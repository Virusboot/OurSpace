import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ourspace_flutter/core/crypto/e2ee_crypto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stage 8 E2EE Media & Production Security Test Suite', () {
    setUp(() {
      E2EECryptoService.clearReplayCache();
    });

    test('1. Identity Key Pinning & TOFU Trust Verification', () async {
      const recipientId = 'usr_alice_tofu';
      final keys1 = await E2EECryptoService.generateIdentityKeys();
      final edKey1 = keys1['ed25519PublicKeyHex']!;

      final status1 = await E2EECryptoService.verifyAndPinIdentityKey(recipientId, edKey1);
      expect(status1, equals(IdentityTrustStatus.trusted));

      final status2 = await E2EECryptoService.verifyAndPinIdentityKey(recipientId, edKey1);
      expect(status2, equals(IdentityTrustStatus.verified));

      final keys2 = await E2EECryptoService.generateIdentityKeys();
      final edKey2 = keys2['ed25519PublicKeyHex']!;
      final status3 = await E2EECryptoService.verifyAndPinIdentityKey(recipientId, edKey2);
      expect(status3, equals(IdentityTrustStatus.changed));
    });

    test('2. Safety Number / Fingerprint is deterministic and 12-digit grouped', () async {
      final aliceKeys = await E2EECryptoService.generateIdentityKeys();
      final bobKeys = await E2EECryptoService.generateIdentityKeys();

      final fn1 = E2EECryptoService.computeSafetyNumber(aliceKeys['ed25519PublicKeyHex']!, bobKeys['ed25519PublicKeyHex']!);
      final fn2 = E2EECryptoService.computeSafetyNumber(bobKeys['ed25519PublicKeyHex']!, aliceKeys['ed25519PublicKeyHex']!);

      expect(fn1, equals(fn2));
      expect(fn1.length, equals(14));
      expect(fn1.split(' ').length, equals(3));
    });

    test('3. E2EE V3: Ephemeral X25519 ECDH + AES-256-GCM + Ed25519 Signature', () async {
      final aliceKeys = await E2EECryptoService.generateIdentityKeys();
      final bobKeys = await E2EECryptoService.generateIdentityKeys();
      const plaintext = 'Zero-Knowledge Ephemeral Message';

      final ciphertext = await E2EECryptoService.encryptPayloadAsync(
        plaintext: plaintext,
        recipientPublicKey: bobKeys['publicKey']!,
        senderPrivateKeyHex: aliceKeys['privateKey']!,
        senderEd25519PrivateKeyHex: aliceKeys['ed25519PrivateKeyHex']!,
        conversationId: 'conv_123',
      );

      expect(ciphertext.startsWith('E2EE_V3_AES_GCM:'), isTrue);

      final decrypted = await E2EECryptoService.decryptPayloadAsync(
        encryptedPayload: ciphertext,
        recipientPrivateKeyHex: bobKeys['privateKey']!,
        conversationId: 'conv_123',
      );

      expect(decrypted, equals(plaintext));
    });

    test('4. Signature Coverage: Tampering with sender Ed25519 key fails signature verification', () async {
      final aliceKeys = await E2EECryptoService.generateIdentityKeys();
      final bobKeys = await E2EECryptoService.generateIdentityKeys();
      final eveKeys = await E2EECryptoService.generateIdentityKeys();

      final ciphertext = await E2EECryptoService.encryptPayloadAsync(
        plaintext: 'Top Secret Payload',
        recipientPublicKey: bobKeys['publicKey']!,
        senderPrivateKeyHex: aliceKeys['privateKey']!,
        senderEd25519PrivateKeyHex: aliceKeys['ed25519PrivateKeyHex']!,
        conversationId: 'conv_123',
      );

      final parts = ciphertext.split(':');
      parts[1] = eveKeys['ed25519PublicKeyHex']!;
      final tampered = parts.join(':');

      final decrypted = await E2EECryptoService.decryptPayloadAsync(
        encryptedPayload: tampered,
        recipientPrivateKeyHex: bobKeys['privateKey']!,
        conversationId: 'conv_123',
      );

      expect(decrypted.contains('signature verification failed'), isTrue);
    });

    test('5. Signature Coverage: Tampering with Ephemeral X25519 key fails signature verification', () async {
      final aliceKeys = await E2EECryptoService.generateIdentityKeys();
      final bobKeys = await E2EECryptoService.generateIdentityKeys();
      final eveKeys = await E2EECryptoService.generateIdentityKeys();

      final ciphertext = await E2EECryptoService.encryptPayloadAsync(
        plaintext: 'Top Secret Payload',
        recipientPublicKey: bobKeys['publicKey']!,
        senderPrivateKeyHex: aliceKeys['privateKey']!,
        senderEd25519PrivateKeyHex: aliceKeys['ed25519PrivateKeyHex']!,
        conversationId: 'conv_123',
      );

      final parts = ciphertext.split(':');
      parts[2] = eveKeys['x25519PublicKeyHex']!;
      final tampered = parts.join(':');

      final decrypted = await E2EECryptoService.decryptPayloadAsync(
        encryptedPayload: tampered,
        recipientPrivateKeyHex: bobKeys['privateKey']!,
        conversationId: 'conv_123',
      );

      expect(decrypted.contains('signature verification failed'), isTrue);
    });

    test('6. Domain-Separated HKDF: Mismatched conversation ID fails decryption', () async {
      final aliceKeys = await E2EECryptoService.generateIdentityKeys();
      final bobKeys = await E2EECryptoService.generateIdentityKeys();

      final ciphertext = await E2EECryptoService.encryptPayloadAsync(
        plaintext: 'Scoped Conversation Message',
        recipientPublicKey: bobKeys['publicKey']!,
        senderPrivateKeyHex: aliceKeys['privateKey']!,
        senderEd25519PrivateKeyHex: aliceKeys['ed25519PrivateKeyHex']!,
        conversationId: 'conv_ROOM_A',
      );

      final decrypted = await E2EECryptoService.decryptPayloadAsync(
        encryptedPayload: ciphertext,
        recipientPrivateKeyHex: bobKeys['privateKey']!,
        conversationId: 'conv_ROOM_B',
      );

      expect(decrypted.contains('signature verification failed') || decrypted.contains('Authentication failed'), isTrue);
    });

    test('7. Envelope Replay Protection: Replaying identical signature envelope is rejected', () async {
      final aliceKeys = await E2EECryptoService.generateIdentityKeys();
      final bobKeys = await E2EECryptoService.generateIdentityKeys();

      final ciphertext = await E2EECryptoService.encryptPayloadAsync(
        plaintext: 'One-Time Non-Replayable Payload',
        recipientPublicKey: bobKeys['publicKey']!,
        senderPrivateKeyHex: aliceKeys['privateKey']!,
        senderEd25519PrivateKeyHex: aliceKeys['ed25519PrivateKeyHex']!,
        conversationId: 'conv_replay',
      );

      final dec1 = await E2EECryptoService.decryptPayloadAsync(
        encryptedPayload: ciphertext,
        recipientPrivateKeyHex: bobKeys['privateKey']!,
        conversationId: 'conv_replay',
      );
      expect(dec1, equals('One-Time Non-Replayable Payload'));

      final dec2 = await E2EECryptoService.decryptPayloadAsync(
        encryptedPayload: ciphertext,
        recipientPrivateKeyHex: bobKeys['privateKey']!,
        conversationId: 'conv_replay',
      );

      expect(dec2, equals('[Replay Error: Duplicate ciphertext envelope rejected]'));
    });

    test('8. Media E2EE: Client-side authenticated AES-256-GCM media encryption & decryption', () async {
      final rawMediaBytes = Uint8List.fromList(utf8.encode('BINARY_IMAGE_DATA_BYTES_123456789'));

      final encResult = await E2EECryptoService.encryptMediaBytesAsync(rawMediaBytes);
      final mediaKeyHex = encResult['mediaKeyHex'] as String;
      final mediaEnvelope = encResult['mediaEnvelope'] as String;

      expect(mediaEnvelope.startsWith('OURSPACE_MEDIA_V1:'), isTrue);
      expect(mediaEnvelope.contains('BINARY_IMAGE_DATA'), isFalse);

      final decBytes = await E2EECryptoService.decryptMediaBytesAsync(
        mediaEnvelope: mediaEnvelope,
        mediaKeyHex: mediaKeyHex,
      );

      expect(utf8.decode(decBytes), equals('BINARY_IMAGE_DATA_BYTES_123456789'));
    });

    test('9. Media E2EE: Tampered media ciphertext fails MAC verification', () async {
      final rawMediaBytes = Uint8List.fromList(utf8.encode('SENSITIVE_MEDIA_FILE'));
      final encResult = await E2EECryptoService.encryptMediaBytesAsync(rawMediaBytes);
      final mediaKeyHex = encResult['mediaKeyHex'] as String;
      final mediaEnvelope = encResult['mediaEnvelope'] as String;

      final parts = mediaEnvelope.split(':');
      parts[2] = '${parts[2].substring(0, parts[2].length - 4)}AAAA'; // Tamper media ciphertext
      final corruptedEnvelope = parts.join(':');

      expect(
        () async => await E2EECryptoService.decryptMediaBytesAsync(
          mediaEnvelope: corruptedEnvelope,
          mediaKeyHex: mediaKeyHex,
        ),
        throwsA(anything),
      );
    });

    test('10. Media E2EE: Wrong media key fails decryption', () async {
      final rawMediaBytes = Uint8List.fromList(utf8.encode('CONFIDENTIAL_PHOTO'));
      final encResult1 = await E2EECryptoService.encryptMediaBytesAsync(rawMediaBytes);
      final encResult2 = await E2EECryptoService.encryptMediaBytesAsync(rawMediaBytes);

      final mediaEnvelope = encResult1['mediaEnvelope'] as String;
      final wrongKeyHex = encResult2['mediaKeyHex'] as String; // Wrong key

      expect(
        () async => await E2EECryptoService.decryptMediaBytesAsync(
          mediaEnvelope: mediaEnvelope,
          mediaKeyHex: wrongKeyHex,
        ),
        throwsA(anything),
      );
    });
  });
}
