import { createIdentity, getUserByUsername, getUserByPrivateId } from '../services/identityService';
import { createCallLink, verifyAndGetCallLink } from '../services/callLinkService';
import { createMessage, markMessageRead, markMessageDelivered, getPendingUndeliveredMessagesForUser, getOrCreateConversation, getConversationMessages } from '../services/chatService';
import { purgeExpiredData } from '../services/cleanupService';

describe('Backend Security & Privacy Services Test Suite', () => {
  let createdUser: any;

  test('1. Identity creation should generate Private ID and store public key without plaintext secrets', async () => {
    const res = await createIdentity('@harsh01', 'mock_public_key_pem_123', 'recovery_key_phrase_321');
    expect(res.user).toBeDefined();
    expect(res.user.privateId).toMatch(/^USER-[A-Z0-9]{6}$/);
    expect(res.user.username).toBe('@harsh01');
    expect(res.user.publicKey).toBe('mock_public_key_pem_123');
    expect(res.token).toBeDefined();
    createdUser = res.user;
  });

  test('2. Lookup user by username and Private ID', async () => {
    const byName = await getUserByUsername('@harsh01');
    expect(byName).not.toBeNull();
    expect(byName?.id).toBe(createdUser.id);

    const byId = await getUserByPrivateId(createdUser.privateId);
    expect(byId).not.toBeNull();
    expect(byId?.username).toBe('@harsh01');
  });

  test('3. Generate secure random token call link with optional PIN', async () => {
    const link = await createCallLink({
      hostId: createdUser.id,
      callType: 'video',
      durationMinutes: 30,
      pin: '1234'
    });

    expect(link.token).toBeDefined();
    expect(link.token.length).toBe(32);
    expect(link.shareUrl).toBe(`/c/${link.token}`);

    // Verify without PIN (should require PIN)
    const verNoPin = await verifyAndGetCallLink(link.token);
    expect(verNoPin.valid).toBe(false);
    expect(verNoPin.error).toBe('PIN_REQUIRED');

    // Verify with correct PIN
    const verWithPin = await verifyAndGetCallLink(link.token, '1234');
    expect(verWithPin.valid).toBe(true);
    expect(verWithPin.link?.callType).toBe('video');
  });

  test('4. Create E2EE message and test disappearing timer read receipt', async () => {
    const msg = await createMessage({
      conversationId: 'conv_123',
      senderId: createdUser.id,
      encryptedPayload: 'AES_GCM_ENCRYPTED_BLOB_BASE64',
      messageType: 'text',
      ttlSeconds: 1 // 1 second expiry
    });

    expect(msg.id).toBeDefined();
    expect(msg.expiresAt).not.toBeNull();

    // Mark message read
    const read = await markMessageRead(msg.id, 1);
    expect(read?.readAt).not.toBeNull();

    // Wait 1.1 seconds and run cleanup purge
    await new Promise(r => setTimeout(r, 1200));
    const purgeResult = await purgeExpiredData();
    expect(purgeResult.messagesPurged).toBeGreaterThanOrEqual(1);
  });

  test('5. Case-insensitive username lookup', async () => {
    const byNameMixed = await getUserByUsername('  @HARSH01  ');
    expect(byNameMixed).not.toBeNull();
    expect(byNameMixed?.id).toBe(createdUser.id);
  });

  test('6. Conversation IDOR authorization check', async () => {
    const user2 = await createIdentity('@alice_test', 'mock_pub_key_2');
    const convId = 'conv_secure_99';

    // Alice is not in conv_secure_99
    await expect(getConversationMessages(convId, user2.user.id))
      .rejects.toThrow('UNAUTHORIZED: You are not a participant in this conversation');
  });

  test('7. Message Idempotency check', async () => {
    const customId = 'msg_client_unique_id_999';
    const msg1 = await createMessage({
      id: customId,
      conversationId: 'conv_idem_1',
      senderId: createdUser.id,
      encryptedPayload: 'ENCRYPTED_1',
      messageType: 'text'
    });
    expect(msg1.id).toBe(customId);

    // Re-sending with same client message ID should return original message without duplicate insert
    const msg2 = await createMessage({
      id: customId,
      conversationId: 'conv_idem_1',
      senderId: createdUser.id,
      encryptedPayload: 'ENCRYPTED_1',
      messageType: 'text'
    });
    expect(msg2.id).toBe(customId);
  });

  test('8. Message Delivery and Read Status transitions', async () => {
    const msg = await createMessage({
      conversationId: 'conv_status_1',
      senderId: createdUser.id,
      encryptedPayload: 'ENCRYPTED_PAYLOAD_STATUS',
      messageType: 'text'
    });
    expect(msg.status).toBe('sent');

    const delivered = await markMessageDelivered(msg.id);
    expect(delivered?.status).toBe('delivered');
    expect(delivered?.deliveredAt).not.toBeNull();

    const read = await markMessageRead(msg.id);
    expect(read?.status).toBe('seen');
    expect(read?.readAt).not.toBeNull();
  });

  test('9. Pending offline message retrieval for disconnected users', async () => {
    const userB = await createIdentity('@bob_offline', 'pub_key_bob');
    const convId = await getOrCreateConversation(createdUser.id, userB.user.id);

    // User A sends message to User B while User B is offline
    const pendingMsg = await createMessage({
      conversationId: convId,
      senderId: createdUser.id,
      encryptedPayload: 'PAYLOAD_FOR_BOB',
      messageType: 'text'
    });

    const pendingList = await getPendingUndeliveredMessagesForUser(userB.user.id);
    expect(pendingList.length).toBeGreaterThanOrEqual(1);
    expect(pendingList.some(m => m.id === pendingMsg.id)).toBe(true);
  });
});
