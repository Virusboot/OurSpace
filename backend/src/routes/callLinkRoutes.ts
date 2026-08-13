import { Router } from 'express';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';
import { createCallLink, verifyAndGetCallLink, revokeCallLink } from '../services/callLinkService';
import { authRateLimiter } from '../middleware/rateLimiter';

const router = Router();

// Create call link (Requires Auth)
router.post('/create', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { callType, durationMinutes, pin, oneTime } = req.body;
    if (!callType || (callType !== 'audio' && callType !== 'video')) {
      return res.status(400).json({ error: 'Valid callType (audio or video) is required' });
    }

    const result = await createCallLink({
      hostId: req.user!.userId,
      callType,
      durationMinutes,
      pin,
      oneTime
    });

    return res.json(result);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// Resolve & verify call link (Public/Guest endpoint with rate limiting)
router.post('/resolve/:token', authRateLimiter, async (req, res) => {
  try {
    const { token } = req.params;
    const { pin } = req.body;

    const verification = await verifyAndGetCallLink(token, pin);
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
    return res.status(500).json({ error: err.message });
  }
});

// Revoke call link
router.post('/revoke/:linkId', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { linkId } = req.params;
    const revoked = await revokeCallLink(linkId, req.user!.userId);
    if (!revoked) {
      return res.status(400).json({ error: 'Link not found or user unauthorized to revoke' });
    }
    return res.json({ success: true, message: 'Call link successfully revoked' });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
