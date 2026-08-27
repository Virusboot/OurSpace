import { Router } from 'express';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';
import { getOrCreateConversation, getConversationMessages, markMessageRead } from '../services/chatService';

const router = Router();

router.post('/conversation', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { recipientId } = req.body;
    if (!recipientId) return res.status(400).json({ error: 'recipientId is required' });

    const conversationId = await getOrCreateConversation(req.user!.userId, recipientId);
    return res.json({ conversationId });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

router.get('/messages/:conversationId', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { conversationId } = req.params;
    const messages = await getConversationMessages(conversationId, req.user!.userId);
    return res.json({ messages });
  } catch (err: any) {
    const status = err.message?.includes('UNAUTHORIZED') ? 403 : 500;
    return res.status(status).json({ error: err.message });
  }
});

router.post('/messages/:messageId/read', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { messageId } = req.params;
    const { readTtlSeconds } = req.body;
    const updated = await markMessageRead(messageId, readTtlSeconds);
    return res.json({ message: updated });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

export default router;
