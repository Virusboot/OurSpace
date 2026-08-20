import { Router } from 'express';
import { getUserByUsername, getUserByPrivateId, getUserById, getUserCount } from '../services/identityService';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';
import { activeConnections } from '../websocket/socketServer';

const router = Router();

import { isPgActive, getPgPool, inMemoryDb } from '../db';

let lastDbError = '';
export function setLastDbError(err: string) { lastDbError = err; }

router.get('/count', async (req, res) => {
  try {
    const count = await getUserCount();
    return res.json({ totalAccounts: count });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

router.get('/db-status', (req, res) => {
  return res.json({ active: isPgActive(), error: lastDbError });
});

router.get('/online', authenticateToken, async (req, res) => {
  try {
    const onlineUserIds = Array.from(activeConnections.keys());
    const onlineUsers = [];
    for (const id of onlineUserIds) {
      if (id.startsWith('usr_')) {
        const user = await getUserById(id);
        if (user) {
          onlineUsers.push({
            id: user.id,
            username: user.username,
            privateId: user.privateId,
            publicKey: user.publicKey
          });
        }
      }
    }
    return res.json(onlineUsers);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

router.get('/me', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const user = await getUserById(req.user!.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    return res.json({ id: user.id, privateId: user.privateId, username: user.username, publicKey: user.publicKey });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

router.get('/lookup', authenticateToken, async (req, res) => {
  try {
    const { query } = req.query;
    if (!query || typeof query !== 'string' || query.trim().length < 2) {
      return res.status(400).json({ error: 'Search query must be at least 2 characters' });
    }

    const cleanQuery = query.trim().toLowerCase();
    const usernameSearch = cleanQuery.startsWith('@') ? cleanQuery : `@${cleanQuery}`;
    const partialSearch = usernameSearch.replace('@', '');

    if (isPgActive()) {
      const pool = getPgPool();
      const result = await pool?.query(
        `SELECT id, private_id as "privateId", username, public_key as "publicKey"
         FROM users
         WHERE LOWER(username) LIKE $1
            OR UPPER(private_id) = $2
         ORDER BY CASE WHEN LOWER(username) = $3 THEN 0 ELSE 1 END
         LIMIT 10`,
        [`%${partialSearch}%`, cleanQuery.toUpperCase(), usernameSearch]
      );
      const users = result?.rows || [];
      if (users.length === 0) return res.status(404).json({ error: 'No users found' });
      return res.json(users[0]);
    } else {
      const allUsers = Array.from((inMemoryDb as any).usersByUsername.values()) as any[];
      const matches = allUsers.filter((u: any) =>
        u.username.toLowerCase().includes(partialSearch) ||
        u.privateId.toUpperCase() === cleanQuery.toUpperCase()
      );
      if (matches.length === 0) return res.status(404).json({ error: 'No users found' });
      const u = matches[0];
      return res.json({ id: u.id, privateId: u.privateId, username: u.username, publicKey: u.publicKey });
    }
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
