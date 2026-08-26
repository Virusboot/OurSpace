import { v4 as uuidv4 } from 'uuid';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { inMemoryDb, isPgActive, getPgPool } from '../db';
import { config } from '../config';

export interface UserRecord {
  id: string;
  privateId: string;
  username: string;
  publicKey: string;
  recoveryHash: string;
  createdAt: string;
  updatedAt: string;
}

export function generatePrivateId(): string {
  const bytes = crypto.randomBytes(3).toString('hex').toUpperCase(); // 6 chars
  return `USER-${bytes}`;
}

export async function createIdentity(username: string, publicKey: string, recoveryKey: string = ''): Promise<{ user: UserRecord; token: string }> {
  const cleanUsername = username.trim().toLowerCase();
  if (!cleanUsername.startsWith('@')) {
    throw new Error('Username must start with @');
  }

  if (cleanUsername.length < 3) {
    throw new Error('Username must be at least 3 characters');
  }

  // Check existing username
  if (isPgActive()) {
    const pool = getPgPool();
    const existing = await pool?.query('SELECT id FROM users WHERE LOWER(username) = $1', [cleanUsername]);
    if (existing && existing.rows.length > 0) {
      throw new Error('Username is already taken');
    }
  } else {
    if (inMemoryDb.usersByUsername.has(cleanUsername)) {
      throw new Error('Username is already taken');
    }
  }

  const id = uuidv4();
  const privateId = generatePrivateId();
  const recoveryHash = recoveryKey ? await bcrypt.hash(recoveryKey, 10) : '';
  const now = new Date().toISOString();

  const user: UserRecord = {
    id,
    privateId,
    username: cleanUsername,
    publicKey,
    recoveryHash,
    createdAt: now,
    updatedAt: now
  };

  if (isPgActive()) {
    const pool = getPgPool();
    await pool?.query(
      `INSERT INTO users (id, private_id, username, public_key, recovery_hash, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [id, privateId, cleanUsername, publicKey, recoveryHash, now, now]
    );
  } else {
    inMemoryDb.users.set(id, user);
    inMemoryDb.usersByPrivateId.set(privateId, user);
    inMemoryDb.usersByUsername.set(cleanUsername, user);
  }

  const token = jwt.sign({ userId: id, privateId, username: cleanUsername }, config.jwtSecret, { expiresIn: '30d' });

  return { user, token };
}

export async function getUserByUsername(username: string): Promise<UserRecord | null> {
  const cleanUsername = username.trim().toLowerCase();
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query('SELECT id, private_id as "privateId", username, public_key as "publicKey", created_at as "createdAt", updated_at as "updatedAt" FROM users WHERE LOWER(username) = $1', [cleanUsername]);
    return res?.rows[0] || null;
  } else {
    return inMemoryDb.usersByUsername.get(cleanUsername) || null;
  }
}

export async function getUserByPrivateId(privateId: string): Promise<UserRecord | null> {
  const cleanId = privateId.trim().toUpperCase();
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query('SELECT id, private_id as "privateId", username, public_key as "publicKey", created_at as "createdAt", updated_at as "updatedAt" FROM users WHERE UPPER(private_id) = $1', [cleanId]);
    return res?.rows[0] || null;
  } else {
    return inMemoryDb.usersByPrivateId.get(cleanId) || null;
  }
}

export async function getUserById(id: string): Promise<UserRecord | null> {
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query('SELECT id, private_id as "privateId", username, public_key as "publicKey", created_at as "createdAt", updated_at as "updatedAt" FROM users WHERE id = $1', [id]);
    return res?.rows[0] || null;
  } else {
    return inMemoryDb.users.get(id) || null;
  }
}

export async function recoverAccount(privateId: string, recoveryKey: string, newPublicKey: string): Promise<{ user: UserRecord; token: string }> {
  let user: any = null;
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query('SELECT * FROM users WHERE UPPER(private_id) = $1', [privateId.toUpperCase()]);
    user = res?.rows[0];
  } else {
    user = inMemoryDb.usersByPrivateId.get(privateId.toUpperCase());
  }

  if (!user) {
    throw new Error('Account with specified Private ID not found');
  }

  const valid = await bcrypt.compare(recoveryKey, user.recovery_hash || user.recoveryHash);
  if (!valid) {
    throw new Error('Invalid Recovery Key');
  }

  const now = new Date().toISOString();
  if (isPgActive()) {
    const pool = getPgPool();
    await pool?.query('UPDATE users SET public_key = $1, updated_at = $2 WHERE id = $3', [newPublicKey, now, user.id]);
  } else {
    user.publicKey = newPublicKey;
    user.updatedAt = now;
  }

  const token = jwt.sign({ userId: user.id, privateId: user.privateId || user.private_id, username: user.username }, config.jwtSecret, { expiresIn: '30d' });
  return { user, token };
}

export async function getUserCount(): Promise<number> {
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query('SELECT COUNT(*) FROM users');
    return parseInt(res?.rows[0].count || '0', 10);
  } else {
    return inMemoryDb.users.size;
  }
}

export async function deleteUserAccount(userId: string): Promise<boolean> {
  if (isPgActive()) {
    const pool = getPgPool();
    // Cascade delete associated records and user account
    await pool?.query('DELETE FROM users WHERE id = $1', [userId]);
    await pool?.query('DELETE FROM devices WHERE user_id = $1', [userId]);
    await pool?.query('DELETE FROM conversations WHERE user_a_id = $1 OR user_b_id = $1', [userId]);
    await pool?.query('DELETE FROM calls WHERE host_id = $1', [userId]);
    await pool?.query('DELETE FROM call_links WHERE host_id = $1', [userId]);
    await pool?.query('DELETE FROM security_events WHERE user_id = $1', [userId]);
  } else {
    const user = inMemoryDb.users.get(userId);
    if (user) {
      inMemoryDb.users.delete(userId);
      if (user.privateId) inMemoryDb.usersByPrivateId.delete(user.privateId.toUpperCase());
      if (user.username) inMemoryDb.usersByUsername.delete(user.username.toLowerCase());
    }
  }
  return true;
}
