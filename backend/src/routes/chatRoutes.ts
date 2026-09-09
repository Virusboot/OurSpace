import { Router } from 'express';
import { authenticateToken, AuthRequest } from '../middleware/authMiddleware';
import { getOrCreateConversation, getConversationMessages, markMessageRead } from '../services/chatService';
import { getUserById, getUserByUsername, getUserByPrivateId } from '../services/identityService';
import { isProductionEnv } from '../db';

const router = Router();

router.post('/conversation', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { recipientId } = req.body;
    if (!recipientId || typeof recipientId !== 'string' || recipientId.trim().length === 0) {
      return res.status(400).json({ error: 'recipientId is required' });
    }

    const cleanRecipient = recipientId.trim();
    const currentUserId = req.user!.userId;

    // Resolve recipient user to canonical user ID
    let targetUser = await getUserById(cleanRecipient);
    if (!targetUser) {
      if (cleanRecipient.startsWith('@') || !cleanRecipient.includes('-')) {
        targetUser = await getUserByUsername(cleanRecipient);
      } else {
        targetUser = await getUserByPrivateId(cleanRecipient);
      }
    }

    if (!targetUser) {
      return res.status(404).json({ error: 'Recipient user not found' });
    }

    if (targetUser.id === currentUserId) {
      return res.status(400).json({ error: 'Cannot start conversation with yourself' });
    }

    const conversationId = await getOrCreateConversation(currentUserId, targetUser.id);
    return res.json({ conversationId });
  } catch (err: any) {
    return res.status(500).json({ error: isProductionEnv() ? 'Failed to start conversation' : err.message });
  }
});

router.get('/messages/:conversationId', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { conversationId } = req.params;
    const messages = await getConversationMessages(conversationId, req.user!.userId);
    return res.json({ messages });
  } catch (err: any) {
    const status = err.message?.includes('UNAUTHORIZED') ? 403 : 500;
    return res.status(status).json({ error: isProductionEnv() && status === 500 ? 'Failed to fetch messages' : err.message });
  }
});

router.post('/messages/:messageId/read', authenticateToken, async (req: AuthRequest, res) => {
  try {
    const { messageId } = req.params;
    const { readTtlSeconds } = req.body;
    const updated = await markMessageRead(messageId, req.user!.userId, readTtlSeconds);
    if (!updated) {
      return res.status(404).json({ error: 'Message not found' });
    }
    return res.json({ message: updated });
  } catch (err: any) {
    const status = err.message?.includes('UNAUTHORIZED') ? 403 : 500;
    return res.status(status).json({ error: isProductionEnv() && status === 500 ? 'Failed to mark message read' : err.message });
  }
});

export default router;
