import { v4 as uuidv4 } from 'uuid';
import crypto from 'crypto';
import bcrypt from 'bcryptjs';
import { inMemoryDb, isPgActive, getPgPool } from '../db';

export interface CallLinkRecord {
  id: string;
  callId: string;
  randomToken: string; // returned only on creation
  tokenHash: string;
  pinHash: string | null;
  expiresAt: string;
  revoked: boolean;
  oneTime: boolean;
  hostId: string;
  callType: 'audio' | 'video';
  createdAt: string;
}

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export async function createCallLink(params: {
  hostId: string;
  callType: 'audio' | 'video';
  durationMinutes?: number;
  pin?: string;
  oneTime?: boolean;
}): Promise<{ linkId: string; callId: string; token: string; shareUrl: string; expiresAt: string }> {
  const linkId = uuidv4();
  const callId = uuidv4();
  const token = crypto.randomBytes(16).toString('hex'); // 32 random hex chars
  const tokenHash = hashToken(token);
  
  const duration = params.durationMinutes && params.durationMinutes > 0 ? params.durationMinutes : 60; // default 60 min
  const expiresAt = new Date(Date.now() + duration * 60 * 1000).toISOString();
  const now = new Date().toISOString();

  let pinHash: string | null = null;
  if (params.pin && params.pin.trim() !== '') {
    pinHash = await bcrypt.hash(params.pin, 10);
  }

  const oneTime = params.oneTime ?? false;

  const record: CallLinkRecord = {
    id: linkId,
    callId,
    randomToken: token,
    tokenHash,
    pinHash,
    expiresAt,
    revoked: false,
    oneTime,
    hostId: params.hostId,
    callType: params.callType,
    createdAt: now
  };

  if (isPgActive()) {
    const pool = getPgPool();
    await pool?.query(
      `INSERT INTO call_links (id, call_id, token_hash, pin_hash, expires_at, revoked, one_time, host_id, call_type, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
      [linkId, callId, tokenHash, pinHash, expiresAt, false, oneTime, params.hostId, params.callType, now]
    );
  } else {
    inMemoryDb.callLinks.set(tokenHash, record);
  }

  return {
    linkId,
    callId,
    token,
    shareUrl: `/c/${token}`,
    expiresAt
  };
}

export async function verifyAndGetCallLink(token: string, pin?: string): Promise<{ valid: boolean; error?: string; link?: CallLinkRecord }> {
  const tokenHash = hashToken(token);
  let record: CallLinkRecord | null = null;

  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      `SELECT id, call_id as "callId", token_hash as "tokenHash", pin_hash as "pinHash", expires_at as "expiresAt", revoked, one_time as "oneTime", host_id as "hostId", call_type as "callType", created_at as "createdAt"
       FROM call_links WHERE token_hash = $1 OR call_id = $2 OR id = $2`,
      [tokenHash, token]
    );
    record = res?.rows[0] || null;
  } else {
    record = inMemoryDb.callLinks.get(tokenHash) || null;
    if (!record) {
      for (const r of inMemoryDb.callLinks.values()) {
        if (r.tokenHash === token || r.callId === token || r.id === token || r.randomToken === token) {
          record = r;
          break;
        }
      }
    }
  }

  if (!record) {
    return { valid: false, error: 'Call link not found or invalid' };
  }

  if (record.revoked) {
    return { valid: false, error: 'This private call link has been revoked' };
  }

  if (new Date(record.expiresAt) < new Date()) {
    return { valid: false, error: 'This private call link has expired' };
  }

  if (record.pinHash) {
    if (!pin) {
      return { valid: false, error: 'PIN_REQUIRED' };
    }
    const pinMatches = await bcrypt.compare(pin, record.pinHash);
    if (!pinMatches) {
      return { valid: false, error: 'Invalid call PIN' };
    }
  }

  return { valid: true, link: record };
}

export async function revokeCallLink(linkId: string, hostId: string): Promise<boolean> {
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      'UPDATE call_links SET revoked = TRUE WHERE id = $1 AND host_id = $2',
      [linkId, hostId]
    );
    return (res?.rowCount || 0) > 0;
  } else {
    for (const record of inMemoryDb.callLinks.values()) {
      if (record.id === linkId && record.hostId === hostId) {
        record.revoked = true;
        return true;
      }
    }
    return false;
  }
}
