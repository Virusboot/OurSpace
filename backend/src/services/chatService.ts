import { v4 as uuidv4 } from 'uuid';
import { inMemoryDb, isPgActive, getPgPool } from '../db';

export interface MessageRecord {
  id: string;
  conversationId: string;
  senderId: string;
  encryptedPayload: string;
  messageType: 'text' | 'image' | 'view_once';
  status: 'sending' | 'sent' | 'delivered' | 'seen' | 'failed';
  deliveredAt: string | null;
  readAt: string | null;
  expiresAt: string | null;
  createdAt: string;
}

export async function getOrCreateConversation(userAId: string, userBId: string): Promise<string> {
  // Normalize conversation pair order
  const [first, second] = [userAId, userBId].sort();

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
    try {
      await pool?.query('INSERT INTO conversations (id, user_a_id, user_b_id) VALUES ($1, $2, $3)', [id, first, second]);
      return id;
    } catch (err) {
      // If unique constraint caught concurrent creation, return existing
      const retry = await pool?.query(
        'SELECT id FROM conversations WHERE (user_a_id = $1 AND user_b_id = $2) OR (user_a_id = $2 AND user_b_id = $1)',
        [first, second]
      );
      if (retry && retry.rows.length > 0) {
        return retry.rows[0].id;
      }
      throw err;
    }
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
  id?: string;
  conversationId: string;
  senderId: string;
  encryptedPayload: string;
  messageType: 'text' | 'image' | 'view_once';
  ttlSeconds?: number;
  status?: 'sending' | 'sent' | 'delivered' | 'seen' | 'failed';
}): Promise<MessageRecord> {
  const id = params.id && params.id.trim().length > 0 ? params.id : uuidv4();
  const now = new Date().toISOString();
  let expiresAt: string | null = null;
  
  if (params.ttlSeconds && params.ttlSeconds > 0) {
    expiresAt = new Date(Date.now() + params.ttlSeconds * 1000).toISOString();
  }

  const initialStatus = params.status || 'sent';

  const msg: MessageRecord = {
    id,
    conversationId: params.conversationId,
    senderId: params.senderId,
    encryptedPayload: params.encryptedPayload,
    messageType: params.messageType,
    status: initialStatus,
    deliveredAt: initialStatus === 'delivered' ? now : null,
    readAt: null,
    expiresAt,
    createdAt: now
  };

  if (isPgActive()) {
    const pool = getPgPool();
    // Idempotency check: Return existing message if ID already exists
    const existing = await pool?.query('SELECT * FROM messages WHERE id = $1', [id]);
    if (existing && existing.rows.length > 0) {
      const r = existing.rows[0];
      return {
        id: r.id,
        conversationId: r.conversation_id,
        senderId: r.sender_id,
        encryptedPayload: r.encrypted_payload,
        messageType: r.message_type,
        status: r.status || 'sent',
        deliveredAt: r.delivered_at,
        readAt: r.read_at,
        expiresAt: r.expires_at,
        createdAt: r.created_at
      };
    }

    await pool?.query(
      `INSERT INTO messages (id, conversation_id, sender_id, encrypted_payload, message_type, status, delivered_at, expires_at, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [id, params.conversationId, params.senderId, params.encryptedPayload, params.messageType, initialStatus, msg.deliveredAt, expiresAt, now]
    );
  } else {
    if (inMemoryDb.messages.has(id)) {
      return inMemoryDb.messages.get(id);
    }
    inMemoryDb.messages.set(id, msg);
  }

  return msg;
}

export async function markMessageDelivered(messageId: string): Promise<MessageRecord | null> {
  const deliveredAt = new Date().toISOString();

  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      `UPDATE messages SET status = 'delivered', delivered_at = COALESCE(delivered_at, $1) WHERE id = $2 RETURNING *`,
      [deliveredAt, messageId]
    );
    if (res && res.rows.length > 0) {
      const r = res.rows[0];
      return {
        id: r.id,
        conversationId: r.conversation_id,
        senderId: r.sender_id,
        encryptedPayload: r.encrypted_payload,
        messageType: r.message_type,
        status: r.status,
        deliveredAt: r.delivered_at,
        readAt: r.read_at,
        expiresAt: r.expires_at,
        createdAt: r.created_at
      };
    }
    return null;
  } else {
    const msg = inMemoryDb.messages.get(messageId);
    if (!msg) return null;
    msg.status = 'delivered';
    if (!msg.deliveredAt) msg.deliveredAt = deliveredAt;
    return msg;
  }
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
      `UPDATE messages SET status = 'seen', read_at = $1, expires_at = COALESCE($2, expires_at) WHERE id = $3 RETURNING *`,
      [readAt, expiresAt, messageId]
    );
    if (res && res.rows.length > 0) {
      const r = res.rows[0];
      return {
        id: r.id,
        conversationId: r.conversation_id,
        senderId: r.sender_id,
        encryptedPayload: r.encrypted_payload,
        messageType: r.message_type,
        status: r.status,
        deliveredAt: r.delivered_at,
        readAt: r.read_at,
        expiresAt: r.expires_at,
        createdAt: r.created_at
      };
    }
    return null;
  } else {
    const msg = inMemoryDb.messages.get(messageId);
    if (!msg) return null;
    msg.status = 'seen';
    msg.readAt = readAt;
    if (expiresAt) {
      msg.expiresAt = expiresAt;
    }
    return msg;
  }
}

export async function getPendingUndeliveredMessagesForUser(userId: string): Promise<MessageRecord[]> {
  const now = new Date().toISOString();
  if (isPgActive()) {
    const pool = getPgPool();
    const res = await pool?.query(
      `SELECT m.id, m.conversation_id as "conversationId", m.sender_id as "senderId",
              m.encrypted_payload as "encryptedPayload", m.message_type as "messageType",
              m.status, m.delivered_at as "deliveredAt", m.read_at as "readAt",
              m.expires_at as "expiresAt", m.created_at as "createdAt"
       FROM messages m
       JOIN conversations c ON m.conversation_id = c.id
       WHERE (c.user_a_id = $1 OR c.user_b_id = $1)
         AND m.sender_id != $1
         AND m.status = 'sent'
         AND (m.expires_at IS NULL OR m.expires_at > $2)
       ORDER BY m.created_at ASC`,
      [userId, now]
    );
    return res?.rows || [];
  } else {
    const result: MessageRecord[] = [];
    for (const msg of inMemoryDb.messages.values()) {
      if (msg.senderId !== userId && msg.status === 'sent') {
        const conv = inMemoryDb.conversations.get(msg.conversationId);
        if (conv && (conv.userAId === userId || conv.userBId === userId)) {
          if (!msg.expiresAt || new Date(msg.expiresAt) > new Date()) {
            result.push(msg);
          }
        }
      }
    }
    return result.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
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
      `SELECT id, conversation_id as "conversationId", sender_id as "senderId", encrypted_payload as "encryptedPayload", message_type as "messageType", status, delivered_at as "deliveredAt", expires_at as "expiresAt", read_at as "readAt", created_at as "createdAt"
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
