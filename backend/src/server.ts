import http from 'http';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config';
import { initDb } from './db';
import { initRedis } from './redis';
import { startCleanupCron } from './services/cleanupService';
import authRoutes from './routes/authRoutes';
import userRoutes from './routes/userRoutes';
import chatRoutes from './routes/chatRoutes';
import callLinkRoutes from './routes/callLinkRoutes';
import mediaRoutes from './routes/mediaRoutes';
import { apiRateLimiter } from './middleware/rateLimiter';
import { initWebSocketServer } from './websocket/socketServer';

const app = express();

// Security Headers & Middlewares
app.use(helmet());
app.use(cors({ origin: config.corsOrigin, credentials: true }));
app.use(express.json({ limit: '10mb' }));
app.use(apiRateLimiter);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

// REST API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/call-links', callLinkRoutes);
app.use('/api/media', mediaRoutes);

// HTTP & WebSocket Server Setup
const server = http.createServer(app);
initWebSocketServer(server);

// Initialize DB, Redis, and Background Services
async function bootstrap() {
  await initDb();
  await initRedis();
  startCleanupCron(10000); // 10s automated server-side TTL purge

  server.listen(config.port, () => {
    console.log(`=================================================`);
    console.log(`  OURSPACE BACKEND SERVER RUNNING`);
    console.log(`  Port: ${config.port}`);
    console.log(`  Environment: ${config.env}`);
    console.log(`  Health Check: http://localhost:${config.port}/health`);
    console.log(`=================================================`);
  });
}

bootstrap().catch(err => {
  console.error('Fatal bootstrap error:', err);
  process.exit(1);
});

export default app;
