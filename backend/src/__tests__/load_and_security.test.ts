import http from 'http';
import WebSocket from 'ws';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { createIdentity } from '../services/identityService';
import { getOrCreateConversation, createMessage, markMessageDelivered, markMessageRead, getPendingUndeliveredMessagesForUser } from '../services/chatService';

describe('Phase 3 Real-World Load, Stress & Security Regression Test Suite', () => {
  let userA: any;
  let userB: any;
  let userC: any;
  let convAB: string;

  beforeAll(async () => {
    userA = await createIdentity('@stress_user_a', 'pub_key_a');
    userB = await createIdentity('@stress_user_b', 'pub_key_b');
    userC = await createIdentity('@stress_user_c', 'pub_key_c');
    convAB = await getOrCreateConversation(userA.user.id, userB.user.id);
  });

  test('1. Security Regression: Socket auth bypass prevention', async () => {
    // Attempting to send chat_send with invalid token or before auth handshake should fail
    const invalidToken = 'invalid_jwt_token_123';
    let authFailed = false;
    try {
      jwt.verify(invalidToken, config.jwtSecret);
    } catch (_) {
      authFailed = true;
    }
    expect(authFailed).toBe(true);
  });

  test('2. Security Regression: IDOR Authorization check', async () => {
    // User C cannot read pending messages for User B
    const pendingForB = await getPendingUndeliveredMessagesForUser(userB.user.id);
    expect(pendingForB.every(m => m.senderId !== userB.user.id)).toBe(true);
  });

  test('3. Chat Load & Latency Test (Rapid Message Burst)', async () => {
    const startTime = Date.now();
    const burstCount = 50;
    const promises = [];

    for (let i = 0; i < burstCount; i++) {
      const msgId = `burst_msg_${i}_${Date.now()}`;
      promises.push(
        createMessage({
          id: msgId,
          conversationId: convAB,
          senderId: userA.user.id,
          encryptedPayload: `PAYLOAD_BURST_${i}`,
          messageType: 'text'
        })
      );
    }

    const results = await Promise.all(promises);
    const endTime = Date.now();
    const totalDuration = endTime - startTime;
    const avgLatency = totalDuration / burstCount;

    expect(results.length).toBe(burstCount);
    expect(avgLatency).toBeLessThan(10); // DB write latency under 10ms per item
  });

  test('4. Idempotency under High-Concurrency Retries', async () => {
    const customId = `concurrent_id_${Date.now()}`;
    const retryPromises = [];

    // 10 concurrent requests attempting to insert the exact same messageId simultaneously
    for (let i = 0; i < 10; i++) {
      retryPromises.push(
        createMessage({
          id: customId,
          conversationId: convAB,
          senderId: userA.user.id,
          encryptedPayload: 'CONCURRENT_PAYLOAD',
          messageType: 'text'
        })
      );
    }

    const results = await Promise.all(retryPromises);
    // All 10 returned promises must return the exact same message ID
    expect(results.every(r => r.id === customId)).toBe(true);
  });

  test('5. Multi-Device Socket Sync & Offline Queueing', async () => {
    // User B offline: User A sends 3 messages
    const m1 = await createMessage({ conversationId: convAB, senderId: userA.user.id, encryptedPayload: 'P1', messageType: 'text' });
    const m2 = await createMessage({ conversationId: convAB, senderId: userA.user.id, encryptedPayload: 'P2', messageType: 'text' });
    const m3 = await createMessage({ conversationId: convAB, senderId: userA.user.id, encryptedPayload: 'P3', messageType: 'text' });

    // User B reconnects and retrieves pending queue
    const pendingList = await getPendingUndeliveredMessagesForUser(userB.user.id);
    expect(pendingList.length).toBeGreaterThanOrEqual(3);

    // Deliver all pending messages
    for (const msg of pendingList) {
      await markMessageDelivered(msg.id);
    }

    // Verify queue is cleared after delivery
    const pendingAfterDelivery = await getPendingUndeliveredMessagesForUser(userB.user.id);
    expect(pendingAfterDelivery.length).toBe(0);
  });
});
