import { inMemoryDb, isPgActive, getPgPool } from '../db';

export async function purgeExpiredData(): Promise<{ messagesPurged: number; mediaPurged: number; linksPurged: number }> {
  const now = new Date().toISOString();
  let messagesPurged = 0;
  let mediaPurged = 0;
  let linksPurged = 0;

  if (isPgActive()) {
    const pool = getPgPool();
    
    // Purge expired media
    const mediaRes = await pool?.query('DELETE FROM media WHERE expires_at IS NOT NULL AND expires_at <= $1', [now]);
    mediaPurged = mediaRes?.rowCount || 0;

    // Purge expired messages
    const msgRes = await pool?.query('DELETE FROM messages WHERE expires_at IS NOT NULL AND expires_at <= $1', [now]);
    messagesPurged = msgRes?.rowCount || 0;

    // Purge expired call links
    const linkRes = await pool?.query('DELETE FROM call_links WHERE expires_at <= $1', [now]);
    linksPurged = linkRes?.rowCount || 0;
  } else {
    // In-memory purging
    for (const [id, media] of inMemoryDb.media.entries()) {
      if (media.expiresAt && new Date(media.expiresAt) <= new Date()) {
        inMemoryDb.media.delete(id);
        mediaPurged++;
      }
    }

    for (const [id, msg] of inMemoryDb.messages.entries()) {
      if (msg.expiresAt && new Date(msg.expiresAt) <= new Date()) {
        inMemoryDb.messages.delete(id);
        messagesPurged++;
      }
    }

    for (const [key, link] of inMemoryDb.callLinks.entries()) {
      if (new Date(link.expiresAt) <= new Date()) {
        inMemoryDb.callLinks.delete(key);
        linksPurged++;
      }
    }
  }

  if (messagesPurged > 0 || mediaPurged > 0 || linksPurged > 0) {
    console.log(`[Cleanup Cron] Purged expired data: ${messagesPurged} messages, ${mediaPurged} media items, ${linksPurged} call links.`);
  }

  return { messagesPurged, mediaPurged, linksPurged };
}

export function startCleanupCron(intervalMs: number = 10000) {
  setInterval(async () => {
    try {
      await purgeExpiredData();
    } catch (err) {
      console.error('[Cleanup Cron] Error running automated purge:', err);
    }
  }, intervalMs);
  console.log(`[Cleanup Cron] Background TTL auto-purge worker started (interval: ${intervalMs}ms).`);
}
