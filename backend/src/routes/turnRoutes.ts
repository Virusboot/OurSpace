import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { config } from '../config';
import { authenticateToken } from '../middleware/authMiddleware';
import rateLimit from 'express-rate-limit';

const router = Router();

// ---------------------------------------------------------------------------
// TURN credential rate limiter — prevents credential farming abuse
// 10 credential requests per user per 15 minutes is generous for normal use.
// ---------------------------------------------------------------------------
const turnRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req: any) => req.user?.userId || req.ip,
  message: { error: 'Too many TURN credential requests. Please wait before retrying.' }
});

/**
 * GET /api/v1/turn-credentials
 *
 * Generates dynamic time-limited TURN ICE credentials using HMAC-SHA1
 * compatible with Coturn's --use-auth-secret / static-auth-secret mode.
 *
 * Credential format (RFC 5389 / Coturn compatible):
 *   username = "<unix_expiry_timestamp>:<userId>"
 *   credential = HMAC-SHA1(TURN_SECRET, username) encoded as base64
 *
 * Credentials expire after ttlSeconds (default: 86400 = 24h).
 * The TURN_SECRET is NEVER returned to the client.
 * The TURN_SECRET is NEVER logged.
 */
router.get('/', authenticateToken, turnRateLimiter, (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.userId || 'guest';
    const ttlSeconds = 86400; // 24-hour credential lifetime
    const expiry = Math.floor(Date.now() / 1000) + ttlSeconds;

    // Coturn-compatible username format: "<expiry>:<userId>"
    const username = `${expiry}:${userId}`;

    // HMAC-SHA1 — matches Coturn's use-auth-secret verification
    const hmac = crypto.createHmac('sha1', config.turnServer.secret);
    hmac.update(username);
    const credential = hmac.digest('base64');

    // Build ICE server list — always include STUN fallback
    const iceServers: Array<Record<string, any>> = [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' },
    ];

    // Add TURN relay (UDP port 3478) if configured
    const turnUrl = config.turnServer.urls;
    if (turnUrl && turnUrl.startsWith('turn:')) {
      iceServers.push({
        urls: turnUrl,
        username,
        credential,
      });

      // Add TURN over TCP (port 3478 ?transport=tcp) for restricted NATs
      const turnTcp = turnUrl.includes('?transport=') ? turnUrl : `${turnUrl}?transport=tcp`;
      iceServers.push({
        urls: turnTcp,
        username,
        credential,
      });
    }

    // Add TURNS (TLS) if configured — port 5349 typical
    const turnTlsUrl = config.turnServer.urlsTls;
    if (turnTlsUrl && turnTlsUrl.startsWith('turns:')) {
      iceServers.push({
        urls: turnTlsUrl,
        username,
        credential,
      });
    }

    // Fallback TURN config for when TURN_URL is not yet configured
    if (!turnUrl || !turnUrl.startsWith('turn:')) {
      iceServers.push({
        urls: 'turn:turn.ourspace.app:3478',
        username,
        credential,
      });
      iceServers.push({
        urls: 'turn:turn.ourspace.app:3478?transport=tcp',
        username,
        credential,
      });
      iceServers.push({
        urls: 'turns:turn.ourspace.app:5349',
        username,
        credential,
      });
    }

    // Return ICE config — credential and secret are safe (credential is HMAC output, not the secret itself)
    return res.json({
      success: true,
      iceServers,
      ttlSeconds,
      expiresAt: new Date(expiry * 1000).toISOString(),
    });

  } catch (err: any) {
    // Do NOT log err.message if it could contain credential data
    console.error('[TurnRoutes] Failed to generate TURN credentials');
    return res.status(500).json({ error: 'Failed to generate ICE server configuration' });
  }
});

export default router;
