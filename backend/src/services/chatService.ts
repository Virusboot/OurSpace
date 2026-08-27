import { v4 as uuidv4 } from 'uuid';
import { inMemoryDb, isPgActive, getPgPool } from '../db';

export interface MessageRecord {
  id: string;
  conversationId: string;
  senderId: string;
  encryptedPayload: string;
  messageType: 'text' | 'image' | 'view_once';
  expiresAt: string | null;
  readAt: string | null;
  createdAt: string;
}

export async function getOrCreateConversation(userAId: string, userBId: string): Promise<string> {
  // Normalize conversation pair order
  const [first, second] = [userAId, userBId].sort();
  const convKey = `${first}:${second}`;

  if (isPgActive()) {
    const pool = getPgPool();
    const existing = await pool?.query(
      'SELECT id FROM conversations WHERE (user_a_id = $1 AND user_b_id = $2) OR (user_a_id = $2 AND user_b_id = $1)',
      [first, second]
    );
    if (existing && existing.rows.length > 0) {
      return existing.rows[0].id;
    }
    const id = uuidv4();
    await pool?.query('INSERT INTO conversations (id, user_a_id, user_b_id) VALUES ($1, $2, $3)', [id, first, second]);
    return id;
  } else {
    for (const [id, conv] of inMemoryDb.conversations.entries()) {
      if ((conv.userAId === first && conv.userBId === second) || (conv.userAId === second && conv.userBId === first)) {
        return id;
      }
    }
    const id = uuidv4();
    inMemoryDb.conversations.set(id, { id, userAId: first, userBId: second, createdAt: new Date().toISOString() });
    return id;
  }
}

export async function createMessage(params: {
  conversationId: string;
  senderId: string;
  encryptedPayload: string;
  messageType: 'text' | 'image' | 'view_once';
  ttlSeconds?: number;
}): Promise<MessageRecord> {
  const id = uuidv4();
  const now = new Date().toISOString();
  let expiresAt: string | null = null;
  
  if (params.ttlSeconds && params.ttlSeconds > 0) {
    expiresAt = new Date(Date.now() + params.ttlSeconds * 1000).toISOString();
  }

  const msg: MessageRecord = {
    id,
    conversationId: params.conversationId,
    senderId: params.senderId,
    encryptedPayload: params.encryptedPayload,
    messageType: params.messageType,
    expiresAt,
    readAt: null,
    createdAt: now
  };

  if (isPgActive()) {
    const pool = getPgPool();
    await pool?.query(
      `INSERT INTO messages (id, conversation_id, sender_id, encrypted_payload, message_type, expires_at, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [id, params.conversationId, params.senderId, params.encryptedPayload, params.messageType, expiresAt, now]
    );
  } else {
    inMemoryDb.messages.set(id, msg);
  }

  return msg;
}

export async function markMessageRead(messageId: string, readTtlSeconds?: number): Promise<MessageRecord | null> {
  const readAt = new Date().toISOString();
  let expiresAt: string | null = null;

  if (readTtlSeconds && readTtlSeconds > 0) {
    expiresAt = new Date(Date.now() + readTtlSeconds * 1000).toISOString();
  }

  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      `UPDATE messages SET read_at = $1, expires_at = COALESCE($2, expires_at) WHERE id = $3 RETURNING *`,
      [readAt, expiresAt, messageId]
    );
    return res?.rows[0] || null;
  } else {
    const msg = inMemoryDb.messages.get(messageId);
    if (!msg) return null;
    msg.readAt = readAt;
    if (expiresAt) {
      msg.expiresAt = expiresAt;
    }
    return msg;
  }
}

export async function isUserInConversation(userId: string, conversationId: string): Promise<boolean> {
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      'SELECT id FROM conversations WHERE id = $1 AND (user_a_id = $2 OR user_b_id = $2)',
      [conversationId, userId]
    );
    return !!(res && res.rows.length > 0);
  } else {
    const conv = inMemoryDb.conversations.get(conversationId);
    if (!conv) return false;
    return conv.userAId === userId || conv.userBId === userId;
  }
}

export async function getConversationMessages(conversationId: string, requestingUserId?: string): Promise<MessageRecord[]> {
  if (requestingUserId) {
    const allowed = await isUserInConversation(requestingUserId, conversationId);
    if (!allowed) {
      throw new Error('UNAUTHORIZED: You are not a participant in this conversation');
    }
  }

  const now = new Date().toISOString();
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      `SELECT id, conversation_id as "conversationId", sender_id as "senderId", encrypted_payload as "encryptedPayload", message_type as "messageType", expires_at as "expiresAt", read_at as "readAt", created_at as "createdAt"
       FROM messages
       WHERE conversation_id = $1 AND (expires_at IS NULL OR expires_at > $2)
       ORDER BY created_at ASC`,
      [conversationId, now]
    );
    return res?.rows || [];
  } else {
    const result: MessageRecord[] = [];
    for (const msg of inMemoryDb.messages.values()) {
      if (msg.conversationId === conversationId) {
        if (!msg.expiresAt || new Date(msg.expiresAt) > new Date()) {
          result.push(msg);
        }
      }
    }
    return result.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
  }
}

export async function saveMediaBlob(messageId: string, encryptedBlobRef: string, ttlSeconds: number = 300): Promise<string> {
  const mediaId = uuidv4();
  const expiresAt = new Date(Date.now() + ttlSeconds * 1000).toISOString();
  const now = new Date().toISOString();

  if (isPgActive()) {
    const pool = getPgPool();
    await pool?.query(
      `INSERT INTO media (id, message_id, encrypted_blob_ref, expires_at, created_at)
       VALUES ($1, $2, $3, $4, $5)`,
      [mediaId, messageId, encryptedBlobRef, expiresAt, now]
    );
  } else {
    inMemoryDb.media.set(mediaId, {
      id: mediaId,
      messageId,
      encryptedBlobRef,
      viewedAt: null,
      expiresAt,
      createdAt: now
    });
  }

  return mediaId;
}

export async function getAndConsumeMediaBlob(mediaId: string): Promise<string | null> {
  const now = new Date().toISOString();
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      `SELECT encrypted_blob_ref FROM media WHERE id = $1 AND (expires_at IS NULL OR expires_at > $2)`,
      [mediaId, now]
    );
    const blobRef = res?.rows[0]?.encrypted_blob_ref || null;
    // Mark viewed and mark for deletion
    await pool?.query(`DELETE FROM media WHERE id = $1`, [mediaId]);
    return blobRef;
  } else {
    const item = inMemoryDb.media.get(mediaId);
    if (!item) return null;
    if (item.expiresAt && new Date(item.expiresAt) < new Date()) {
      inMemoryDb.media.delete(mediaId);
      return null;
    }
    inMemoryDb.media.delete(mediaId);
    return item.encryptedBlobRef;
  }
}
