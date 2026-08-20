import { Router } from 'express';
import { getUserByUsername, getUserByPrivateId, getUserById, getUserCount } from '../services/identityService';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';
import { activeConnections } from '../websocket/socketServer';

const router = Router();

import { isPgActive } from '../db';

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
    if (!query || typeof query !== 'string') {
      return res.status(400).json({ error: 'Search query required' });
    }

    let user = null;
    if (query.startsWith('@')) {
      user = await getUserByUsername(query);
    } else if (query.startsWith('USER-')) {
      user = await getUserByPrivateId(query);
    } else if (query.startsWith('usr_') || query.length === 36) {
      user = await getUserById(query);
    } else {
      user = (await getUserByUsername(`@${query}`)) || (await getUserByPrivateId(query)) || (await getUserById(query));
    }

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json({
      id: user.id,
      privateId: user.privateId,
      username: user.username,
      publicKey: user.publicKey
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
