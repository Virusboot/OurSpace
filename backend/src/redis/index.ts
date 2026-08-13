import Redis from 'ioredis';
import { config } from '../config';

let redisClient: Redis | null = null;
let useRedis = false;

// Fallback In-memory Redis simulation
class InMemoryRedis {
  private store = new Map<string, { value: string; expiresAt?: number }>();

  async get(key: string): Promise<string | null> {
    const item = this.store.get(key);
    if (!item) return null;
    if (item.expiresAt && Date.now() > item.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return item.value;
  }

  async set(key: string, value: string, mode?: string, duration?: number): Promise<'OK'> {
    let expiresAt: number | undefined;
    if (mode === 'EX' && duration) {
      expiresAt = Date.now() + duration * 1000;
    } else if (mode === 'PX' && duration) {
      expiresAt = Date.now() + duration;
    }
    this.store.set(key, { value, expiresAt });
    return 'OK';
  }

  async del(key: string): Promise<number> {
    const existed = this.store.has(key);
    this.store.delete(key);
    return existed ? 1 : 0;
  }
}

export const memoryRedis = new InMemoryRedis();

export async function initRedis() {
  try {
    const client = new Redis(config.redisUrl, {
      maxRetriesPerRequest: 1,
      connectTimeout: 2000,
      retryStrategy: () => null // Disable looping reconnects if Redis server isn't present
    });
    
    await new Promise((resolve, reject) => {
      client.on('connect', () => resolve(true));
      client.on('error', (err) => reject(err));
    });

    redisClient = client;
    useRedis = true;
    console.log('[Redis] Connected to Redis successfully.');
  } catch (err) {
    console.warn('[Redis] Connection failed. Using In-Memory Redis store fallback.');
    useRedis = false;
  }
}

export async function cacheSet(key: string, value: string, ttlSeconds?: number): Promise<void> {
  if (useRedis && redisClient) {
    if (ttlSeconds) {
      await redisClient.set(key, value, 'EX', ttlSeconds);
    } else {
      await redisClient.set(key, value);
    }
  } else {
    await memoryRedis.set(key, value, ttlSeconds ? 'EX' : undefined, ttlSeconds);
  }
}

export async function cacheGet(key: string): Promise<string | null> {
  if (useRedis && redisClient) {
    return await redisClient.get(key);
  }
  return await memoryRedis.get(key);
}

export async function cacheDel(key: string): Promise<void> {
  if (useRedis && redisClient) {
    await redisClient.del(key);
  } else {
    await memoryRedis.del(key);
  }
}
