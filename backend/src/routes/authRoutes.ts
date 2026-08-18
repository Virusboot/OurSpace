import { Router } from 'express';
import { createIdentity, recoverAccount } from '../services/identityService';
import { authRateLimiter } from '../middleware/rateLimiter';
import { inMemoryDb } from '../db';

const router = Router();

// Store registered users by email in memory for backend auth
const usersByEmail = new Map<string, any>();

router.post('/login', authRateLimiter, async (req, res) => {
  try {
    const { email, username, password } = req.body;
    const loginIdentifier = (username || email || '').trim().toLowerCase();
    if (!loginIdentifier || !password) {
      return res.status(400).json({ error: 'Username/Email and password are required' });
    }

    let existing = null;
    if (loginIdentifier.includes('@') && loginIdentifier.includes('.')) {
      // Email format login
      existing = usersByEmail.get(loginIdentifier);
    } else {
      // Username or Private ID format login
      const formattedUsername = loginIdentifier.startsWith('@') ? loginIdentifier : `@${loginIdentifier}`;
      let dbRecord = inMemoryDb.usersByUsername.get(formattedUsername);
      if (!dbRecord) {
        dbRecord = inMemoryDb.usersByPrivateId.get(loginIdentifier.toUpperCase());
      }
      if (dbRecord) {
        const derivedEmail = `${dbRecord.privateId.toLowerCase()}@ourspace.local`;
        existing = usersByEmail.get(derivedEmail);
      }
    }

    if (!existing) {
      return res.status(400).json({ error: 'No account found. Please register first.' });
    }
    if (existing.password !== password) {
      return res.status(400).json({ error: 'Incorrect password' });
    }
    return res.json({
      user: {
        id: existing.id,
        name: existing.name,
        email: existing.email,
        username: existing.username,
        privateId: existing.privateId,
      },
      token: 'jwt_token_' + Date.now(),
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message || 'Login failed' });
  }
});

router.post('/register', authRateLimiter, async (req, res) => {
  try {
    const { name, email, password, username } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    const cleanEmail = email.trim().toLowerCase();
    if (usersByEmail.has(cleanEmail)) {
      return res.status(400).json({ error: 'An account with this email already exists' });
    }

    const cleanUsername = username || (email ? '@' + email.split('@')[0] : '@user');
    const privateId = req.body.privateId || (email ? email.split('@')[0].toUpperCase() : 'USER-' + Math.random().toString(36).substring(2, 8).toUpperCase());
    const userId = 'usr_' + Date.now();

    const userObj = {
      id: userId,
      name: name || 'User',
      email: cleanEmail,
      password,
      username: cleanUsername,
      privateId,
      createdAt: new Date().toISOString(),
    };

    usersByEmail.set(cleanEmail, userObj);

    // Save to inMemoryDb maps so they are searchable by other users via lookup
    const lookupRecord = {
      id: userId,
      privateId,
      username: cleanUsername,
      publicKey: 'mock_public_key',
      recoveryHash: password,
      createdAt: userObj.createdAt,
      updatedAt: userObj.createdAt,
    };
    inMemoryDb.users.set(userId, lookupRecord);
    inMemoryDb.usersByPrivateId.set(privateId.toUpperCase(), lookupRecord);
    inMemoryDb.usersByUsername.set(cleanUsername.toLowerCase(), lookupRecord);

    return res.json({
      user: {
        id: userObj.id,
        name: userObj.name,
        email: userObj.email,
        username: userObj.username,
        privateId: userObj.privateId,
      },
      token: 'jwt_token_' + Date.now(),
    });
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
