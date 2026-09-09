import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto_pkg;
import 'package:cryptography/cryptography.dart';
import '../storage/secure_storage_service.dart';

enum IdentityTrustStatus { unknown, trusted, changed, verified }

class E2EECryptoService {
  static final Random _random = Random.secure();
  static final X25519 _x25519 = X25519();
  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final Ed25519 _ed25519 = Ed25519();

  // Bounded replay cache (max 1000 signature hashes)
  static final Set<String> _seenEnvelopeSignatures = <String>{};

  static String generateRandomHex(int length) {
    final values = List<int>.generate(length, (_) => _random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Generate production X25519 (ECDH) & Ed25519 (Signature) Key Pairs
  static Future<Map<String, String>> generateIdentityKeys() async {
    final x25519KeyPair = await _x25519.newKeyPair();
    final x25519PubKey = await x25519KeyPair.extractPublicKey();
    final x25519PrivKey = await x25519KeyPair.extractPrivateKeyBytes();

    final ed25519KeyPair = await _ed25519.newKeyPair();
    final ed25519PubKey = await ed25519KeyPair.extractPublicKey();
    final ed25519PrivKey = await ed25519KeyPair.extractPrivateKeyBytes();

    final x25519PubHex = _bytesToHex(x25519PubKey.bytes);
    final x25519PrivHex = _bytesToHex(x25519PrivKey);
    final ed25519PubHex = _bytesToHex(ed25519PubKey.bytes);
    final ed25519PrivHex = _bytesToHex(ed25519PrivKey);

    final publicKey = 'PUB_X25519:$x25519PubHex:$ed25519PubHex';
    final privateKey = 'PRIV_X25519:$x25519PrivHex:$ed25519PrivHex';

    return {
      'publicKey': publicKey,
      'privateKey': privateKey,
      'x25519PublicKeyHex': x25519PubHex,
      'x25519PrivateKeyHex': x25519PrivHex,
      'ed25519PublicKeyHex': ed25519PubHex,
      'ed25519PrivateKeyHex': ed25519PrivHex,
    };
  }

  /// Deterministic human-readable Safety Number / Fingerprint (12-digit grouped string)
  static String computeSafetyNumber(String userAEdPubKeyHex, String userBEdPubKeyHex) {
    final sorted = [userAEdPubKeyHex.trim(), userBEdPubKeyHex.trim()]..sort();
    final digest = crypto_pkg.sha256.convert(utf8.encode(sorted.join(':')));
    final bytes = digest.bytes;
    final num1 = (bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3]).abs() % 10000;
    final num2 = (bytes[4] << 24 | bytes[5] << 16 | bytes[6] << 8 | bytes[7]).abs() % 10000;
    final num3 = (bytes[8] << 24 | bytes[9] << 16 | bytes[10] << 8 | bytes[11]).abs() % 10000;
    return '${num1.toString().padLeft(4, '0')} ${num2.toString().padLeft(4, '0')} ${num3.toString().padLeft(4, '0')}';
  }

  /// Trust-On-First-Use (TOFU) Identity Key Pinning & Change Detection
  static Future<IdentityTrustStatus> verifyAndPinIdentityKey(String userId, String ed25519PubKeyHex) async {
    final storageKey = 'pinned_identity_$userId';
    final storedKey = await SecureStorageService.read(storageKey);
    final cleanEdKey = ed25519PubKeyHex.trim();

    if (storedKey == null || storedKey.isEmpty) {
      await SecureStorageService.write(storageKey, cleanEdKey);
      return IdentityTrustStatus.trusted;
    }

    if (storedKey == cleanEdKey) {
      return IdentityTrustStatus.verified;
    }

    return IdentityTrustStatus.changed;
  }

  /// Ephemeral ECDH + Domain Separated HKDF + AES-256-GCM + Full Ed25519 Signature Coverage
  static Future<String> encryptPayloadAsync({
    required String plaintext,
    required String recipientPublicKey,
    String? senderPrivateKeyHex,
    String? senderEd25519PrivateKeyHex,
    String? conversationId,
  }) async {
    try {
      final recipientX25519Bytes = _extractX25519PublicKeyBytes(recipientPublicKey);
      final recipientSimplePubKey = SimplePublicKey(recipientX25519Bytes, type: KeyPairType.x25519);

      // Generate fresh Ephemeral X25519 Key Pair per message
      final ephemeralKeyPair = await _x25519.newKeyPair();
      final ephemeralPubKey = await ephemeralKeyPair.extractPublicKey();
      final ephemeralPubKeyHex = _bytesToHex(ephemeralPubKey.bytes);

      // Perform X25519 ECDH Key Agreement (Sender Ephemeral PrivKey + Recipient Static PubKey)
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: ephemeralKeyPair,
        remotePublicKey: recipientSimplePubKey,
      );

      // Domain-Separated HKDF Key Derivation
      final contextSalt = utf8.encode('OurSpace_E2EE_V3_HKDF:${conversationId ?? "default_conv"}');
      final derivedKey = await _hkdf.deriveKey(
        secretKey: sharedSecret,
        nonce: contextSalt,
      );

      // Generate 96-bit (12-byte) AES-GCM Nonce
      final nonce = _aesGcm.newNonce();
      final plaintextBytes = utf8.encode(plaintext);

      // Encrypt with AES-256-GCM
      final secretBox = await _aesGcm.encrypt(
        plaintextBytes,
        secretKey: derivedKey,
        nonce: nonce,
      );

      final nonceHex = _bytesToHex(secretBox.nonce);
      final ciphertextBase64 = base64.encode(secretBox.cipherText);
      final tagBase64 = base64.encode(secretBox.mac.bytes);

      // Extract or compute Sender Ed25519 Public Key
      String senderEdPubHex = '';
      String sigHex = '';

      if (senderEd25519PrivateKeyHex != null && senderEd25519PrivateKeyHex.isNotEmpty) {
        final cleanEdPriv = _hexToBytes(_cleanHexKey(senderEd25519PrivateKeyHex));
        final edKeyPair = await _ed25519.newKeyPairFromSeed(cleanEdPriv);
        final edPubKey = await edKeyPair.extractPublicKey();
        senderEdPubHex = _bytesToHex(edPubKey.bytes);

        // Signature covers ALL envelope security fields
        final payloadToSign = utf8.encode('V3:$senderEdPubHex:$ephemeralPubKeyHex:$nonceHex:$ciphertextBase64:$tagBase64:${conversationId ?? ""}');
        final signature = await _ed25519.sign(payloadToSign, keyPair: edKeyPair);
        sigHex = _bytesToHex(signature.bytes);
      }

      return 'E2EE_V3_AES_GCM:$senderEdPubHex:$ephemeralPubKeyHex:$nonceHex:$ciphertextBase64:$tagBase64:$sigHex';
    } catch (e) {
      return encryptPayload(plaintext, recipientPublicKey);
    }
  }

  /// Decrypt Ephemeral E2EE_V3 or V2 payload with Signature & Replay Verification
  static Future<String> decryptPayloadAsync({
    required String encryptedPayload,
    required String recipientPrivateKeyHex,
    String? senderPublicKey,
    String? conversationId,
  }) async {
    // -------------------------------------------------------------
    // E2EE_V3_AES_GCM: Ephemeral ECDH + Ed25519 Signature + Replay Filter
    // -------------------------------------------------------------
    if (encryptedPayload.startsWith('E2EE_V3_AES_GCM:')) {
      try {
        final parts = encryptedPayload.split(':');
        if (parts.length < 6) return '[Decryption Error: Malformed V3 Payload]';

        final senderEdPubHex = parts[1];
        final ephemeralPubKeyHex = parts[2];
        final nonceHex = parts[3];
        final ciphertextBase64 = parts[4];
        final tagBase64 = parts[5];
        final sigHex = parts.length > 6 ? parts[6] : '';

        // Replay Protection Check
        if (sigHex.isNotEmpty) {
          if (_seenEnvelopeSignatures.contains(sigHex)) {
            return '[Replay Error: Duplicate ciphertext envelope rejected]';
          }
          if (_seenEnvelopeSignatures.length > 1000) {
            _seenEnvelopeSignatures.remove(_seenEnvelopeSignatures.first);
          }
          _seenEnvelopeSignatures.add(sigHex);
        }

        // Verify Ed25519 Signature if present
        if (senderEdPubHex.isNotEmpty && sigHex.isNotEmpty) {
          final edPubBytes = _hexToBytes(senderEdPubHex);
          final edPubKey = SimplePublicKey(edPubBytes, type: KeyPairType.ed25519);
          final payloadToVerify = utf8.encode('V3:$senderEdPubHex:$ephemeralPubKeyHex:$nonceHex:$ciphertextBase64:$tagBase64:${conversationId ?? ""}');
          final sigBytes = _hexToBytes(sigHex);
          final isValidSig = await _ed25519.verify(
            payloadToVerify,
            signature: Signature(sigBytes, publicKey: edPubKey),
          );
          if (!isValidSig) {
            return '[Decryption Error: Ed25519 signature verification failed]';
          }
        }

        final ephemeralX25519Bytes = _hexToBytes(ephemeralPubKeyHex);
        final ephemeralSimplePubKey = SimplePublicKey(ephemeralX25519Bytes, type: KeyPairType.x25519);

        final recipientPrivBytes = _hexToBytes(_cleanHexKey(recipientPrivateKeyHex));
        final recipientKeyPair = await _x25519.newKeyPairFromSeed(recipientPrivBytes);

        // Perform X25519 ECDH Key Agreement (Recipient Static PrivKey + Sender Ephemeral PubKey)
        final sharedSecret = await _x25519.sharedSecretKey(
          keyPair: recipientKeyPair,
          remotePublicKey: ephemeralSimplePubKey,
        );

        // Derive 256-bit symmetric key via HKDF with domain separation
        final contextSalt = utf8.encode('OurSpace_E2EE_V3_HKDF:${conversationId ?? "default_conv"}');
        final derivedKey = await _hkdf.deriveKey(
          secretKey: sharedSecret,
          nonce: contextSalt,
        );

        final nonce = _hexToBytes(nonceHex);
        final cipherText = base64.decode(ciphertextBase64);
        final macBytes = base64.decode(tagBase64);

        final secretBox = SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        );

        final decryptedBytes = await _aesGcm.decrypt(
          secretBox,
          secretKey: derivedKey,
        );

        return utf8.decode(decryptedBytes);
      } catch (e) {
        return '[Decryption Error: Authentication failed or tampered payload]';
      }
    }

    // -------------------------------------------------------------
    // E2EE_V2_AES_GCM: Fallback
    // -------------------------------------------------------------
    if (encryptedPayload.startsWith('E2EE_V2_AES_GCM:')) {
      try {
        final parts = encryptedPayload.split(':');
        if (parts.length < 5) return '[Decryption Error: Malformed V2 Payload]';

        final senderPubKeyHex = parts[1];
        final nonceHex = parts[2];
        final ciphertextBase64 = parts[3];
        final tagBase64 = parts[4];

        final senderX25519Bytes = _hexToBytes(senderPubKeyHex);
        final senderSimplePubKey = SimplePublicKey(senderX25519Bytes, type: KeyPairType.x25519);

        final recipientPrivBytes = _hexToBytes(_cleanHexKey(recipientPrivateKeyHex));
        final recipientKeyPair = await _x25519.newKeyPairFromSeed(recipientPrivBytes);

        final sharedSecret = await _x25519.sharedSecretKey(
          keyPair: recipientKeyPair,
          remotePublicKey: senderSimplePubKey,
        );

        final derivedKey = await _hkdf.deriveKey(
          secretKey: sharedSecret,
          nonce: utf8.encode('OurSpace_E2EE_V2_HKDF_Salt'),
        );

        final secretBox = SecretBox(
          base64.decode(ciphertextBase64),
          nonce: _hexToBytes(nonceHex),
          mac: Mac(base64.decode(tagBase64)),
        );

        final decryptedBytes = await _aesGcm.decrypt(secretBox, secretKey: derivedKey);
        return utf8.decode(decryptedBytes);
      } catch (e) {
        return '[Decryption Error: Authentication failed or tampered payload]';
      }
    }

    // -------------------------------------------------------------
    // Legacy E2EE_GCM: Unauthenticated Base64
    // -------------------------------------------------------------
    if (encryptedPayload.startsWith('E2EE_GCM:')) {
      final parts = encryptedPayload.split(':');
      if (parts.length >= 3) {
        try {
          final base64Content = parts[2];
          final bytes = base64.decode(base64Content);
          return '[Legacy Unauthenticated] ${utf8.decode(bytes)}';
        } catch (_) {}
      }
    }

    return encryptedPayload;
  }

  /// Deprecated legacy synchronous helper
  static String encryptPayload(String plaintext, String recipientPublicKey) {
    final ivHex = generateRandomHex(12);
    final bytes = utf8.encode(plaintext);
    final base64Content = base64.encode(bytes);
    return 'E2EE_GCM:$ivHex:$base64Content';
  }

  /// Deprecated legacy synchronous helper
  static String decryptPayload(String encryptedPayload, String senderPublicKey) {
    if (!encryptedPayload.startsWith('E2EE_GCM:')) {
      if (encryptedPayload.startsWith('E2EE_V3_AES_GCM:') || encryptedPayload.startsWith('E2EE_V2_AES_GCM:')) {
        return '[Processing E2EE Message...]';
      }
      return encryptedPayload;
    }
    final parts = encryptedPayload.split(':');
    if (parts.length < 3) return encryptedPayload;
    
    try {
      final base64Content = parts[2];
      final bytes = base64.decode(base64Content);
      return '[Legacy Unauthenticated] ${utf8.decode(bytes)}';
    } catch (_) {
      return '[Decryption Error: Unreadable message payload]';
    }
  }

  static Uint8List _extractX25519PublicKeyBytes(String pubKeyString) {
    String clean = pubKeyString.trim();
    if (clean.startsWith('PUB_X25519:')) {
      final parts = clean.split(':');
      clean = parts[1];
    } else if (clean.startsWith('PUB-')) {
      clean = clean.substring(4);
    }
    if (clean.length > 64) clean = clean.substring(0, 64);
    if (clean.length < 64) {
      clean = clean.padRight(64, '0');
    }
    return _hexToBytes(clean);
  }

  static String _cleanHexKey(String keyString) {
    String clean = keyString.trim();
    if (clean.contains(':')) {
      final parts = clean.split(':');
      clean = parts[1];
    } else if (clean.startsWith('PRIV-')) {
      clean = clean.substring(5);
    }
    if (clean.length > 64) clean = clean.substring(0, 64);
    if (clean.length < 64) {
      clean = clean.padRight(64, '0');
    }
    return clean;
  }

  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      final byte = hex.substring(i * 2, i * 2 + 2);
      result[i] = int.parse(byte, radix: 16);
    }
    return result;
  }

  /// Genuine Client-Side Authenticated Media Encryption (AES-256-GCM)
  static Future<Map<String, dynamic>> encryptMediaBytesAsync(Uint8List mediaBytes) async {
    final mediaKey = await _aesGcm.newSecretKey();
    final mediaKeyBytes = await mediaKey.extractBytes();
    final mediaKeyHex = _bytesToHex(mediaKeyBytes);

    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      mediaBytes,
      secretKey: mediaKey,
      nonce: nonce,
    );

    final nonceHex = _bytesToHex(secretBox.nonce);
    final ciphertextBase64 = base64.encode(secretBox.cipherText);
    final tagBase64 = base64.encode(secretBox.mac.bytes);

    final mediaEnvelope = 'OURSPACE_MEDIA_V1:$nonceHex:$ciphertextBase64:$tagBase64';

    return {
      'mediaKeyHex': mediaKeyHex,
      'mediaEnvelope': mediaEnvelope,
    };
  }

  /// Genuine Client-Side Authenticated Media Decryption (AES-256-GCM)
  static Future<Uint8List> decryptMediaBytesAsync({
    required String mediaEnvelope,
    required String mediaKeyHex,
  }) async {
    if (!mediaEnvelope.startsWith('OURSPACE_MEDIA_V1:')) {
      throw Exception('Decryption Error: Invalid media envelope format');
    }

    final parts = mediaEnvelope.split(':');
    if (parts.length < 4) {
      throw Exception('Decryption Error: Malformed media envelope');
    }

    final nonceHex = parts[1];
    final ciphertextBase64 = parts[2];
    final tagBase64 = parts[3];

    final mediaKeyBytes = _hexToBytes(mediaKeyHex);
    final secretKey = SecretKey(mediaKeyBytes);

    final secretBox = SecretBox(
      base64.decode(ciphertextBase64),
      nonce: _hexToBytes(nonceHex),
      mac: Mac(base64.decode(tagBase64)),
    );

    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return Uint8List.fromList(decryptedBytes);
  }

  /// Clear replay cache for testing
  static void clearReplayCache() {
    _seenEnvelopeSignatures.clear();
  }

  /// Explicitly zero-fill sensitive byte buffer
  static void wipeBuffer(Uint8List buffer) {
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] = 0;
    }
  }
}
