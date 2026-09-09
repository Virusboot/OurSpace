import { Router } from 'express';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';
import { createCallLink, verifyAndGetCallLink, revokeCallLink } from '../services/callLinkService';
import { authRateLimiter } from '../middleware/rateLimiter';
import { isProductionEnv } from '../db';

const router = Router();

// Create call link (Requires authenticated user)
router.post('/create', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { callType, durationMinutes, pin, oneTime } = req.body;
    if (!callType || (callType !== 'audio' && callType !== 'video')) {
      return res.status(400).json({ error: 'Valid callType (audio or video) is required' });
    }

    const hostId = req.user!.userId;

    const result = await createCallLink({
      hostId,
      callType,
      durationMinutes,
      pin,
      oneTime
    });

    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: isProductionEnv() ? 'Failed to create call link' : err.message });
  }
});

// Resolve & verify call link (Public/Guest endpoint with rate limiting)
router.post('/resolve/:token', authRateLimiter, async (req, res) => {
  try {
    const { token } = req.params;
    const { pin } = req.body;

    if (!token || typeof token !== 'string' || token.trim().length === 0) {
      return res.status(400).json({ error: 'Call link token required' });
    }

    const verification = await verifyAndGetCallLink(token.trim(), pin);
    if (!verification.valid) {
      if (verification.error === 'PIN_REQUIRED') {
        return res.status(401).json({ error: 'PIN_REQUIRED', pinRequired: true });
      }
      return res.status(400).json({ error: verification.error });
    }

    const link = verification.link!;
    return res.json({
      valid: true,
      linkId: link.id,
      callId: link.callId,
      hostId: link.hostId,
      callType: link.callType,
      expiresAt: link.expiresAt,
      oneTime: link.oneTime
    });
  } catch (err: any) {
    return res.status(500).json({ error: isProductionEnv() ? 'Failed to resolve call link' : err.message });
  }
});

// Revoke call link (Requires link owner authentication)
router.post('/revoke/:linkId', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { linkId } = req.params;
    if (!linkId || typeof linkId !== 'string') {
      return res.status(400).json({ error: 'linkId required' });
    }
    const revoked = await revokeCallLink(linkId, req.user!.userId);
    if (!revoked) {
      return res.status(400).json({ error: 'Link not found or user unauthorized to revoke' });
    }
    return res.json({ success: true, message: 'Call link successfully revoked' });
  } catch (err: any) {
    return res.status(500).json({ error: isProductionEnv() ? 'Failed to revoke call link' : err.message });
  }
});

export default router;
