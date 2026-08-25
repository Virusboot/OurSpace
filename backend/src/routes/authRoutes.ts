import { Router } from 'express';
import { createIdentity, recoverAccount } from '../services/identityService';
import { authRateLimiter } from '../middleware/rateLimiter';
import { inMemoryDb } from '../db';

const router = Router();

import { isPgActive, getPgPool } from '../db';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { config } from '../config';

// Store registered users by email in memory for backend auth (fallback only)
const usersByEmail = new Map<string, any>();

router.post('/login', authRateLimiter, async (req, res) => {
  try {
    const { email, username, password } = req.body;
    const loginIdentifier = (username || email || '').trim().toLowerCase();
    if (!loginIdentifier || !password) {
      return res.status(400).json({ error: 'Username/Email and password are required' });
    }

    let existing = null;
    let existingHash = '';

    if (isPgActive()) {
      const pool = getPgPool();
      const withoutAt = loginIdentifier.replace(/^@/, '');
      const withAt = `@${withoutAt}`;
      let query = 'SELECT * FROM users WHERE LOWER(username) = $1 OR LOWER(username) = $2 OR LOWER(private_id) = $1 OR LOWER(private_id) = $3';
      let resDb = await pool?.query(query, [loginIdentifier, withAt, withoutAt]);
      
      // If email format, try extracting private ID
      if (!resDb || resDb.rows.length === 0) {
        if (loginIdentifier.includes('@ourspace.local')) {
           const extractedId = loginIdentifier.split('@')[0];
           resDb = await pool?.query(query, [extractedId]);
        }
      }

      if (resDb && resDb.rows.length > 0) {
        const row = resDb.rows[0];
        existing = {
          id: row.id,
          name: row.username.replace('@', ''),
          email: `${row.private_id.toLowerCase()}@ourspace.local`,
          username: row.username,
          privateId: row.private_id,
        };
        existingHash = row.recovery_hash;
      }
    } else {
      // Fallback in-memory logic
      if (loginIdentifier.includes('@') && loginIdentifier.includes('.')) {
        existing = usersByEmail.get(loginIdentifier);
      } else {
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
      if (existing) existingHash = existing.password;
    }

    if (!existing) {
      return res.status(400).json({ error: 'No account found. Please register first.' });
    }

    // Compare passwords
    const isValid = isPgActive() ? await bcrypt.compare(password, existingHash) : existingHash === password;
    if (!isValid) {
      return res.status(400).json({ error: 'Incorrect password' });
    }

    const token = jwt.sign(
      { userId: existing.id, privateId: existing.privateId, username: existing.username },
      config.jwtSecret,
      { expiresIn: '30d' }
    );

    return res.json({
      user: existing,
      token,
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
    const cleanUsername = username || (email ? '@' + email.split('@')[0] : '@user');
    const privateId = req.body.privateId || (email ? email.split('@')[0].toUpperCase() : 'USER-' + Math.random().toString(36).substring(2, 8).toUpperCase());
    const userId = 'usr_' + Date.now();
    const now = new Date().toISOString();

    if (isPgActive()) {
      const pool = getPgPool();
      // Check if exists
      const existing = await pool?.query('SELECT id FROM users WHERE LOWER(username) = $1 OR UPPER(private_id) = $2', [cleanUsername.toLowerCase(), privateId.toUpperCase()]);
      if (existing && existing.rows.length > 0) {
        return res.status(400).json({ error: 'Username or Private ID already exists' });
      }

      // Hash password using bcrypt
      const hashedPass = await bcrypt.hash(password, 10);

      // Insert into PostgreSQL
      await pool?.query(
        `INSERT INTO users (id, private_id, username, public_key, recovery_hash, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [userId, privateId, cleanUsername, 'mock_public_key', hashedPass, now, now]
      );
    } else {
      if (usersByEmail.has(cleanEmail)) {
        return res.status(400).json({ error: 'An account with this email already exists' });
      }
      const userObj = {
        id: userId,
        name: name || 'User',
        email: cleanEmail,
        password, // stored plaintext in memory only
        username: cleanUsername,
        privateId,
        createdAt: now,
      };
      usersByEmail.set(cleanEmail, userObj);

    const lookupRecord = {
      id: userId,
      privateId,
      username: cleanUsername,
      publicKey: 'mock_public_key',
      recoveryHash: password,
      createdAt: now,
      updatedAt: now,
    };
    inMemoryDb.users.set(userId, lookupRecord);
    inMemoryDb.usersByPrivateId.set(privateId.toUpperCase(), lookupRecord);
    inMemoryDb.usersByUsername.set(cleanUsername.toLowerCase(), lookupRecord);
    }

    const token = jwt.sign(
      { userId: userId, privateId: privateId, username: cleanUsername },
      config.jwtSecret,
      { expiresIn: '30d' }
    );

    return res.json({
      user: {
        id: userId,
        name: name || cleanUsername.replace('@', ''),
        email: cleanEmail,
        username: cleanUsername,
        privateId: privateId,
      },
      token,
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
