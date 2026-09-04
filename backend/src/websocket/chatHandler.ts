import WebSocket from 'ws';
import { createMessage, markMessageRead, markMessageDelivered } from '../services/chatService';
import { sendToUserConnections } from './socketServer';

export async function handleChatMessage(
  ws: WebSocket,
  payload: any,
  activeConnections: Map<string, WebSocket>
) {
  const {
    type,
    conversationId,
    senderId,
    recipientId,
    encryptedPayload,
    messageType,
    ttlSeconds,
    messageId,
    id,
    readTtlSeconds
  } = payload;

  const clientMsgId = messageId || id;

  if (type === 'chat_send') {
    // 1. Create message record with idempotency check
    const msg = await createMessage({
      id: clientMsgId,
      conversationId,
      senderId,
      encryptedPayload,
      messageType: messageType || 'text',
      ttlSeconds
    });

    // 2. Transmit to recipient active device connections if online
    const receivePayload = {
      type: 'chat_receive',
      message: {
        ...msg,
        senderUsername: payload.senderUsername || payload.senderId || 'Someone',
        senderProfileImage: payload.senderProfileImage,
        text: payload.text
      }
    };

    let isDelivered = sendToUserConnections(recipientId, receivePayload);
    
    if (!isDelivered && payload.recipientUsername) {
      const rawUname = payload.recipientUsername.toLowerCase();
      const cleanUname = rawUname.replace(/^@/, '');
      isDelivered = sendToUserConnections(rawUname, receivePayload) ||
                    sendToUserConnections(cleanUname, receivePayload) ||
                    sendToUserConnections(`@${cleanUname}`, receivePayload);
    }
    if (!isDelivered && payload.recipientPrivateId) {
      isDelivered = sendToUserConnections(payload.recipientPrivateId.toUpperCase(), receivePayload) ||
                    sendToUserConnections(payload.recipientPrivateId.toLowerCase(), receivePayload);
    }

    if (isDelivered) {
      await markMessageDelivered(msg.id);
      msg.status = 'delivered';
    }

    // 3. Acknowledge sender's active sockets
    const ackPayload = {
      type: 'chat_ack',
      messageId: msg.id,
      conversationId: msg.conversationId,
      status: msg.status,
      deliveredToRecipient: isDelivered,
      createdAt: msg.createdAt,
      expiresAt: msg.expiresAt
    };

    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(ackPayload));
    }
    sendToUserConnections(senderId, ackPayload);

  } else if (type === 'chat_delivered') {
    if (clientMsgId) {
      const updated = await markMessageDelivered(clientMsgId);
      const ackPayload = {
        type: 'chat_delivered_ack',
        messageId: clientMsgId,
        status: 'delivered',
        deliveredAt: updated?.deliveredAt || new Date().toISOString()
      };
      if (senderId) {
        sendToUserConnections(senderId, ackPayload);
      }
    }
  } else if (type === 'chat_read') {
    if (clientMsgId) {
      const updated = await markMessageRead(clientMsgId, readTtlSeconds);
      const ackPayload = {
        type: 'chat_read_ack',
        messageId: clientMsgId,
        status: 'seen',
        readAt: updated?.readAt,
        expiresAt: updated?.expiresAt
      };
      if (senderId) {
        sendToUserConnections(senderId, ackPayload);
      }
      if (recipientId) {
        sendToUserConnections(recipientId, ackPayload);
      }
    }
  } else if (type === 'chat_typing') {
    const typingPayload = {
      type: 'chat_typing',
      senderId,
      conversationId,
      isTyping: payload.isTyping
    };
    if (recipientId) {
      sendToUserConnections(recipientId, typingPayload);
    }
  }
}
