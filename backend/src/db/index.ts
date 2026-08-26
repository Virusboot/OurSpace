import { Pool } from 'pg';
import { config } from '../config';

// In-Memory Database fallback for zero-dependency standalone execution and testing
class InMemoryDB {
  users = new Map<string, any>(); // id -> user
  usersByPrivateId = new Map<string, any>();
  usersByUsername = new Map<string, any>();
  devices = new Map<string, any>();
  conversations = new Map<string, any>();
  messages = new Map<string, any>(); // id -> message
  media = new Map<string, any>(); // id -> media
  calls = new Map<string, any>();
  callLinks = new Map<string, any>(); // id/tokenHash -> callLink
  securityEvents: any[] = [];
}

export const inMemoryDb = new InMemoryDB();

let pgPool: Pool | null = null;
let usePg = false;

import { setLastDbError } from '../routes/userRoutes';

export async function initDb() {
  try {
    if (pgPool) {
      try { await pgPool.end(); } catch (_) {}
    }

    const pool = new Pool({
      connectionString: config.databaseUrl,
      connectionTimeoutMillis: 8000,
      query_timeout: 10000, // 10s client-side timeout
      statement_timeout: 15000, // 15s server-side timeout
      idleTimeoutMillis: 30000,
      max: 10,
      ssl: config.databaseUrl?.includes('localhost') ? false : { rejectUnauthorized: false }
    });
    
    pool.on('error', (err) => {
      console.error('[Database Pool Error] PostgreSQL client error:', err.message);
      setLastDbError(err.message);
      // Attempt background reconnect
      scheduleDbReconnect();
    });

    // Add hard timeout to connect
    const client = await Promise.race([
      pool.connect(),
      new Promise<never>((_, reject) => setTimeout(() => reject(new Error('PostgreSQL connection timeout (8s)')), 8000))
    ]);
    
    client.release();
    pgPool = pool;
    usePg = true;
    setLastDbError('');
    console.log('[Database] Connected to Supabase PostgreSQL successfully.');
    await createTablesIfNotExist();
  } catch (err: any) {
    console.warn('[Database] PostgreSQL connection failed! Error:', err.message || String(err));
    console.warn('Falling back to In-Memory Database store. Will retry connecting to PostgreSQL in 30s...');
    setLastDbError(err.message || String(err));
    usePg = false;
    scheduleDbReconnect();
  }
}

let dbReconnectTimer: NodeJS.Timeout | null = null;
function scheduleDbReconnect() {
  if (dbReconnectTimer) return;
  dbReconnectTimer = setTimeout(async () => {
    dbReconnectTimer = null;
    if (!usePg) {
      console.log('[Database] Attempting to reconnect to PostgreSQL/Supabase...');
      await initDb();
    }
  }, 30000);
}

async function createTablesIfNotExist() {
  if (!usePg || !pgPool) return;
  
  const query = `
    CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(64) PRIMARY KEY,
      username VARCHAR(64) UNIQUE NOT NULL,
      public_key TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS devices (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
      public_key TEXT NOT NULL,
      device_info TEXT,
      last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS conversations (
      id VARCHAR(64) PRIMARY KEY,
      user_a_id VARCHAR(64) REFERENCES users(id),
      user_b_id VARCHAR(64) REFERENCES users(id),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS messages (
      id VARCHAR(64) PRIMARY KEY,
      conversation_id VARCHAR(64) REFERENCES conversations(id) ON DELETE CASCADE,
      sender_id VARCHAR(64) REFERENCES users(id),
      encrypted_payload TEXT NOT NULL,
      message_type VARCHAR(32) NOT NULL,
      expires_at TIMESTAMP,
      read_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS media (
      id VARCHAR(64) PRIMARY KEY,
      message_id VARCHAR(64) REFERENCES messages(id) ON DELETE CASCADE,
      encrypted_blob_ref TEXT NOT NULL,
      viewed_at TIMESTAMP,
      expires_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS calls (
      id VARCHAR(64) PRIMARY KEY,
      host_id VARCHAR(64) NOT NULL,
      type VARCHAR(16) NOT NULL,
      status VARCHAR(32) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS call_links (
      id VARCHAR(64) PRIMARY KEY,
      call_id VARCHAR(64) NOT NULL,
      token_hash VARCHAR(128) UNIQUE NOT NULL,
      pin_hash TEXT,
      expires_at TIMESTAMP NOT NULL,
      revoked BOOLEAN DEFAULT FALSE,
      one_time BOOLEAN DEFAULT FALSE,
      host_id VARCHAR(64) NOT NULL,
      call_type VARCHAR(16) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS security_events (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64),
      event_type VARCHAR(64) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    ALTER TABLE public.users DROP COLUMN IF EXISTS recovery_hash;
    ALTER TABLE public.users DROP COLUMN IF EXISTS private_id;

    ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.media ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.call_links ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

    CREATE INDEX IF NOT EXISTS idx_users_username_lower ON users (LOWER(username));
  `;
  
  const statements = query.split(';').map(s => s.trim()).filter(s => s.length > 0);
  for (const stmt of statements) {
    try {
      await pgPool.query(stmt);
    } catch (e) {
      console.error('[Database] Failed to initialize table:', e);
    }
  }
  console.log('[Database] Database tables initialized.');
}

export function getPgPool() {
  return pgPool;
}

export function isPgActive() {
  return usePg;
}
