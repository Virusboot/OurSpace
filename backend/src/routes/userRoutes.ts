import { Router } from 'express';
import { getUserByUsername, getUserByPrivateId, getUserById, getUserCount, deleteUserAccount, updateUserProfile } from '../services/identityService';
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

router.put('/profile', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user!.userId;
    const { username, name, bio, profileImage } = req.body;
    
    const result = await updateUserProfile(userId, { username, name, bio, profileImage });

    // Update active WebSocket connection mappings
    const ws = activeConnections.get(userId);
    if (ws && result.user.username) {
      const cleanUname = result.user.username.toLowerCase().replace(/^@/, '');
      activeConnections.set(cleanUname, ws);
      activeConnections.set(`@${cleanUname}`, ws);
    }

    return res.json({
      success: true,
      message: 'Profile details updated and synced successfully in database',
      user: result.user,
      token: result.token
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || 'Failed to update profile' });
  }
});

router.delete('/me', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const userId = req.user!.userId;
    await deleteUserAccount(userId);

    // Disconnect active socket if connected
    const ws = activeConnections.get(userId);
    if (ws) {
      try {
        ws.send(JSON.stringify({ type: 'account_deleted', message: 'Your account has been deleted permanently' }));
        ws.close();
      } catch (_) {}
      activeConnections.delete(userId);
    }

    return res.json({ success: true, message: 'Account and all identity data deleted successfully from database' });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

router.post('/purge-all', async (req, res) => {
  try {
    if (isPgActive()) {
      const pool = getPgPool();
      await pool?.query('TRUNCATE TABLE public.users RESTART IDENTITY CASCADE');
    }
    (inMemoryDb as any).users.clear();
    (inMemoryDb as any).usersByUsername.clear();
    (inMemoryDb as any).usersByPrivateId.clear();
    activeConnections.clear();
    return res.json({ success: true, message: 'All accounts and database records wiped clean successfully' });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

router.get('/lookup', async (req, res) => {
  try {
    const { query } = req.query;
    if (!query || typeof query !== 'string' || query.trim().length < 1) {
      return res.status(400).json({ error: 'Search query required' });
    }

    const cleanQuery = query.trim().toLowerCase();
    const withoutAt = cleanQuery.replace(/^@/, '');
    const withAt = `@${withoutAt}`;
    const upperQuery = cleanQuery.toUpperCase();

    if (isPgActive()) {
      const pool = getPgPool();
      const result = await pool?.query(
        `SELECT id, username, public_key as "publicKey"
         FROM users
         WHERE LOWER(username) LIKE $1 
            OR LOWER(username) LIKE $2
         ORDER BY CASE 
           WHEN LOWER(username) = $3 OR LOWER(username) = $4 THEN 0 
           ELSE 1 
         END
         LIMIT 10`,
        [`${withoutAt}%`, `${withAt}%`, withoutAt, withAt]
      );
      const users = result?.rows || [];
      if (users.length === 0) return res.status(404).json({ error: 'No users found' });
      return res.json(users[0]);
    } else {
      const allUsers = Array.from((inMemoryDb as any).users.values()) as any[];
      const matches = allUsers.filter((u: any) => {
        const uname = (u.username || '').toLowerCase();
        const pid = (u.privateId || '').toUpperCase();
        return uname.includes(withoutAt) || uname.includes(withAt) || pid.includes(upperQuery);
      });
      if (matches.length === 0) return res.status(404).json({ error: 'No users found' });
      const u = matches[0];
      return res.json({ id: u.id, privateId: u.privateId, username: u.username, publicKey: u.publicKey });
    }
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
