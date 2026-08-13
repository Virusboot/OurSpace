import { Router } from 'express';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';
import { saveMediaBlob, getAndConsumeMediaBlob } from '../services/chatService';

const router = Router();

// Upload ephemeral encrypted media blob (base64 string or JSON)
router.post('/upload', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { messageId, encryptedBlob, ttlSeconds } = req.body;
    if (!messageId || !encryptedBlob) {
      return res.status(400).json({ error: 'messageId and encryptedBlob are required' });
    }

    const mediaId = await saveMediaBlob(messageId, encryptedBlob, ttlSeconds || 300);
    return res.json({ mediaId });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// Fetch and consume media blob (view-once / temporary fetch)
router.get('/:mediaId', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { mediaId } = req.params;
    const encryptedBlob = await getAndConsumeMediaBlob(mediaId);
    if (!encryptedBlob) {
      return res.status(404).json({ error: 'Media expired, already viewed, or not found' });
    }
    return res.json({ encryptedBlob });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
