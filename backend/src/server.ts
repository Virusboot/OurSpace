import http from 'http';
import path from 'path';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config';
import { initDb, isPgActive, getPgPool } from './db';
import { initRedis } from './redis';
import { startCleanupCron } from './services/cleanupService';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import chatRoutes from './routes/chatRoutes';
import callLinkRoutes from './routes/callLinkRoutes';
import mediaRoutes from './routes/mediaRoutes';
import turnRoutes from './routes/turnRoutes';
import { apiRateLimiter } from './middleware/rateLimiter';
import { initWebSocketServer } from './websocket/socketServer';

const app = express();

// ---------------------------------------------------------------------------
// Trust reverse proxy (Render / Nginx / AWS ALB inject X-Forwarded-For)
// Required for express-rate-limit to see real client IPs
// ---------------------------------------------------------------------------
app.set('trust proxy', 1);

// ---------------------------------------------------------------------------
// Security Headers & Middleware
// ---------------------------------------------------------------------------
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      connectSrc: ["'self'", 'wss:', 'https:'],
      mediaSrc: ["'self'", 'blob:'],
    }
  },
  crossOriginEmbedderPolicy: false  // required for WebRTC in some browsers
}));

app.use(cors({
  origin: config.corsOrigin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
}));

app.use(express.json({ limit: '10mb' }));
app.use('/downloads', express.static(path.join(__dirname, '../public')));
app.use(apiRateLimiter);

// ---------------------------------------------------------------------------
// Startup state: track whether bootstrap is complete for readiness
// ---------------------------------------------------------------------------
let isReady = false;
let isDraining = false;

// ---------------------------------------------------------------------------
// Health Check — shallow liveness (process is alive)
// Always responds 200 while process is running; used by load balancer ping.
// ---------------------------------------------------------------------------
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'ourspace-backend',
    environment: config.env,
    timestamp: new Date().toISOString(),
  });
});

// ---------------------------------------------------------------------------
// Readiness Check — deep dependency check
// Fails (503) if the process cannot safely persist messages.
// Used by deployment pipelines to confirm the new instance is ready.
// ---------------------------------------------------------------------------
app.get('/ready', async (req, res) => {
  if (!isReady) {
    return res.status(503).json({
      status: 'not_ready',
      reason: 'Bootstrap in progress',
      timestamp: new Date().toISOString(),
    });
  }

  if (isDraining) {
    return res.status(503).json({
      status: 'draining',
      reason: 'Server is shutting down',
      timestamp: new Date().toISOString(),
    });
  }

  // Deep PostgreSQL ping
  let dbStatus: 'connected' | 'degraded' | 'disconnected' = 'disconnected';
  if (isPgActive()) {
    try {
      const pool = getPgPool();
      if (pool) {
        await pool.query('SELECT 1');
        dbStatus = 'connected';
      }
    } catch {
      dbStatus = 'degraded';
    }
  } else {
    dbStatus = 'degraded'; // in-memory fallback — not production-safe
  }

  const isHealthy = dbStatus === 'connected';
  const statusCode = isHealthy ? 200 : 503;

  return res.status(statusCode).json({
    status: isHealthy ? 'ready' : 'degraded',
    database: dbStatus,
    timestamp: new Date().toISOString(),
  });
});

// ---------------------------------------------------------------------------
// REST API Routes
// ---------------------------------------------------------------------------
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/call-links', callLinkRoutes);
app.use('/api/media', mediaRoutes);
app.use('/api/v1/turn-credentials', turnRoutes);
// Keep legacy path for compatibility
app.use('/api/turn-credentials', turnRoutes);

// ---------------------------------------------------------------------------
// HTTP & WebSocket Server Setup
// ---------------------------------------------------------------------------
const server = http.createServer(app);
const wss = initWebSocketServer(server);

// ---------------------------------------------------------------------------
// Graceful Shutdown
// Handles SIGTERM (deployment rotation) and SIGINT (Ctrl+C / local dev)
//
// Shutdown sequence:
//   1. Stop accepting new HTTP connections
//   2. Mark service draining (readiness fails immediately)
//   3. Close new WebSocket upgrades
//   4. Allow in-flight requests up to 10s
//   5. Close WebSocket server
//   6. Close HTTP server
//   7. Close database pool
//   8. Exit cleanly
// ---------------------------------------------------------------------------
async function gracefulShutdown(signal: string) {
  console.log(`[Server] ${signal} received — beginning graceful shutdown.`);
  isDraining = true;

  // 1. Stop new WebSocket upgrades
  server.removeAllListeners('upgrade');

  // 2. Close WS server (no more new WS connections, drain existing)
  wss.close(() => {
    console.log('[Server] WebSocket server closed.');
  });

  // 3. Close HTTP server — no new connections; wait for in-flight requests (10s max)
  server.close(async () => {
    console.log('[Server] HTTP server closed.');

    // 4. Close database pool
    try {
      const pool = getPgPool();
      if (pool) {
        await pool.end();
        console.log('[Server] PostgreSQL pool closed.');
      }
    } catch (err) {
      console.error('[Server] Error closing PostgreSQL pool:', err);
    }

    console.log('[Server] Graceful shutdown complete. Exiting.');
    process.exit(0);
  });

  // Safety timeout — force exit after 15s if shutdown hangs
  setTimeout(() => {
    console.error('[Server] Graceful shutdown timeout exceeded. Forcing exit.');
    process.exit(1);
  }, 15000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT',  () => gracefulShutdown('SIGINT'));

// Unhandled rejection guard — log but do not crash for transient errors
process.on('unhandledRejection', (reason: any) => {
  console.error('[Server] Unhandled promise rejection:', reason?.message || reason);
});

// ---------------------------------------------------------------------------
// Bootstrap
// ---------------------------------------------------------------------------
async function bootstrap() {
  await initDb();
  await initRedis();
  startCleanupCron(10000); // 10s automated server-side TTL purge

  server.listen(config.port, () => {
    isReady = true;
    console.log(`=================================================`);
    console.log(`  OURSPACE BACKEND SERVER RUNNING`);
    console.log(`  Port:        ${config.port}`);
    console.log(`  Environment: ${config.env}`);
    console.log(`  Health:      http://localhost:${config.port}/health`);
    console.log(`  Readiness:   http://localhost:${config.port}/ready`);
    console.log(`=================================================`);
  });
}

bootstrap().catch(err => {
  console.error('[Server] Fatal bootstrap error:', err);
  process.exit(1);
});

export default app;
