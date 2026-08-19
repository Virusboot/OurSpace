import { createIdentity, getUserByUsername, getUserByPrivateId } from '../services/identityService';
import { createCallLink, verifyAndGetCallLink } from '../services/callLinkService';
import { createMessage, markMessageRead } from '../services/chatService';
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
});
