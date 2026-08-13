import { Router } from 'express';
import { createIdentity, recoverAccount } from '../services/identityService';
import { authRateLimiter } from '../middleware/rateLimiter';

const router = Router();

router.post('/register', authRateLimiter, async (req, res) => {
  try {
    const { username, publicKey, recoveryKey } = req.body;
    if (!username || !publicKey || !recoveryKey) {
      return res.status(400).json({ error: 'Username, publicKey, and recoveryKey are required' });
    }
    const result = await createIdentity(username, publicKey, recoveryKey);
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || 'Identity creation failed' });
  }
});

router.post('/recover', authRateLimiter, async (req, res) => {
  try {
    const { privateId, recoveryKey, newPublicKey } = req.body;
    if (!privateId || !recoveryKey || !newPublicKey) {
      return res.status(400).json({ error: 'Private ID, recoveryKey, and newPublicKey are required' });
    }
    const result = await recoverAccount(privateId, recoveryKey, newPublicKey);
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || 'Account recovery failed' });
  }
});

export default router;
