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

export async function initDb() {
  try {
    const pool = new Pool({
      connectionString: config.databaseUrl,
      connectionTimeoutMillis: 5000,
      statement_timeout: 10000, // 10s timeout for any query to prevent infinite hanging
      ssl: config.databaseUrl?.includes('localhost') ? false : { rejectUnauthorized: false }
    });
    const client = await pool.connect();
    client.release();
    pgPool = pool;
    usePg = true;
    console.log('[Database] Connected to PostgreSQL successfully.');
    await createTablesIfNotExist();
  } catch (err) {
    console.warn('[Database] PostgreSQL connection failed! Error:', err);
    console.warn('Falling back to robust In-Memory Database store for development.');
    usePg = false;
  }
}

async function createTablesIfNotExist() {
  if (!usePg || !pgPool) return;
  
  const query = `
    CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(64) PRIMARY KEY,
      private_id VARCHAR(64) UNIQUE NOT NULL,
      username VARCHAR(64) UNIQUE NOT NULL,
      public_key TEXT NOT NULL,
      recovery_hash TEXT NOT NULL,
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
