import { Router } from 'express';
import { getUserByUsername, getUserByPrivateId, getUserById } from '../services/identityService';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';

const router = Router();

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
    } else {
      user = (await getUserByUsername(`@${query}`)) || (await getUserByPrivateId(query));
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
