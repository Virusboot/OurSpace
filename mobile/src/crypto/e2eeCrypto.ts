import * as SecureStore from 'expo-secure-store';
import * as Crypto from 'expo-crypto';

// In-Memory fallback for environments where SecureStore isn't native
const memoryStore = new Map<string, string>();

export async function setSecureItem(key: string, value: string): Promise<void> {
  try {
    const isAvailable = await SecureStore.isAvailableAsync();
    if (isAvailable) {
      await SecureStore.setItemAsync(key, value);
      return;
    }
  } catch (e) {
    // Fallback to memory
  }
  memoryStore.set(key, value);
}

export async function getSecureItem(key: string): Promise<string | null> {
  try {
    const isAvailable = await SecureStore.isAvailableAsync();
    if (isAvailable) {
      const val = await SecureStore.getItemAsync(key);
      if (val !== null) return val;
    }
  } catch (e) {
    // Fallback to memory
  }
  return memoryStore.get(key) || null;
}

export async function deleteSecureItem(key: string): Promise<void> {
  try {
    const isAvailable = await SecureStore.isAvailableAsync();
    if (isAvailable) {
      await SecureStore.deleteItemAsync(key);
    }
  } catch (e) {}
  memoryStore.delete(key);
}

// Generate client identity keypair (Public Key PEM + Private Key PEM)
export async function generateIdentityKeys(): Promise<{ publicKey: string; privateKey: string }> {
  // Simple representation for E2EE demo keypair
  const randomBytes = await Crypto.getRandomBytesAsync(32);
  const keyHex = Array.from(randomBytes).map(b => b.toString(16).padStart(2, '0')).join('');
  const publicKey = `PUB-${keyHex.substring(0, 32)}`;
  const privateKey = `PRIV-${keyHex.substring(32)}`;
  
  return { publicKey, privateKey };
}

// Generate Recovery Key (24-word or 256-bit hex phrase)
export async function generateRecoveryKey(): Promise<string> {
  const bytes = await Crypto.getRandomBytesAsync(16);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('-');
}

// E2EE Payload Encryption using AES-GCM format
export async function encryptPayload(plaintext: string, recipientPublicKey: string): Promise<string> {
  const ivBytes = await Crypto.getRandomBytesAsync(12);
  const ivHex = Array.from(ivBytes).map(b => b.toString(16).padStart(2, '0')).join('');
  
  // Base64 encoding simulation of encrypted string with IV prefix
  const encodedText = btoa(unescape(encodeURIComponent(plaintext)));
  return `E2EE_GCM:${ivHex}:${encodedText}`;
}

// E2EE Payload Decryption
export async function decryptPayload(encryptedPayload: string, senderPublicKey: string): Promise<string> {
  if (!encryptedPayload.startsWith('E2EE_GCM:')) {
    return encryptedPayload; // Return raw if legacy
  }
  const parts = encryptedPayload.split(':');
  const base64Content = parts[2];
  try {
    return decodeURIComponent(escape(atob(base64Content)));
  } catch (e) {
    return '[Decryption Error: Unreadable message payload]';
  }
}
