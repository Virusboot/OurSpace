import WebSocket from 'ws';
import { createMessage, markMessageRead } from '../services/chatService';

export async function handleChatMessage(
  ws: WebSocket,
  payload: any,
  activeConnections: Map<string, WebSocket>
) {
  const { type, conversationId, senderId, recipientId, encryptedPayload, messageType, ttlSeconds, messageId, readTtlSeconds } = payload;

  if (type === 'chat_send') {
    // 1. Create message record (encrypted zero-knowledge payload)
    const msg = await createMessage({
      conversationId,
      senderId,
      encryptedPayload,
      messageType: messageType || 'text',
      ttlSeconds
    });

    // 2. Transmit to recipient if currently online
    let recipientWs = activeConnections.get(recipientId);
    if (!recipientWs && payload.recipientUsername) {
      const rawUname = payload.recipientUsername.toLowerCase();
      const cleanUname = rawUname.replace(/^@/, '');
      recipientWs = activeConnections.get(rawUname) ||
                    activeConnections.get(cleanUname) ||
                    activeConnections.get(`@${cleanUname}`);
    }
    if (!recipientWs && payload.recipientPrivateId) {
      recipientWs = activeConnections.get(payload.recipientPrivateId.toUpperCase()) ||
                    activeConnections.get(payload.recipientPrivateId.toLowerCase());
    }

    const isDelivered = !!(recipientWs && recipientWs.readyState === WebSocket.OPEN);
    if (isDelivered) {
      recipientWs!.send(JSON.stringify({
        type: 'chat_receive',
        message: {
          ...msg,
          senderUsername: payload.senderUsername || payload.senderId || 'Someone',
          senderProfileImage: payload.senderProfileImage,
          text: payload.text
        }
      }));
    }

    // 3. Ack sender
    ws.send(JSON.stringify({
      type: 'chat_ack',
      messageId: msg.id,
      conversationId: msg.conversationId,
      deliveredToRecipient: isDelivered,
      createdAt: msg.createdAt,
      expiresAt: msg.expiresAt
    }));
  } else if (type === 'chat_read') {
    const updated = await markMessageRead(messageId, readTtlSeconds);
    const recipientWs = activeConnections.get(recipientId);
    if (recipientWs && recipientWs.readyState === WebSocket.OPEN) {
      recipientWs.send(JSON.stringify({
        type: 'chat_read_ack',
        messageId,
        readAt: updated?.readAt,
        expiresAt: updated?.expiresAt
      }));
    }
  }
}
