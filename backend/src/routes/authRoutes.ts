import { Router } from 'express';
import { createIdentity, recoverAccount } from '../services/identityService';
import { authRateLimiter } from '../middleware/rateLimiter';

const router = Router();

router.post('/login', authRateLimiter, async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    const username = '@' + email.split('@')[0];
    const privateId = 'USER-' + Math.random().toString(36).substring(2, 8).toUpperCase();
    return res.json({
      user: {
        id: 'usr_' + Date.now(),
        email,
        username,
        privateId,
      },
      token: 'jwt_token_' + Date.now(),
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || 'Login failed' });
  }
});

router.post('/register', authRateLimiter, async (req, res) => {
  try {
    const { email, username, publicKey, recoveryKey } = req.body;
    const cleanUsername = username || (email ? '@' + email.split('@')[0] : '@user');
    const result = await createIdentity(cleanUsername, publicKey || 'PUBKEY_DEFAULT', recoveryKey || 'RECKEY_DEFAULT');
    return res.json(result);
  } catch (err: any) {
    return res.status(400).json({ error: err.message || 'Registration failed' });
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
