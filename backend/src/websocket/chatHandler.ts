import WebSocket from 'ws';
import { createMessage, markMessageRead, markMessageDelivered } from '../services/chatService';
import { getUserByUsername, getUserByPrivateId } from '../services/identityService';
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

    // Resolve recipient to canonical database userId
    let targetUserId = recipientId;
    if (targetUserId && !targetUserId.startsWith('usr_')) {
      if (targetUserId.includes('@') || payload.recipientUsername) {
        const u = await getUserByUsername(payload.recipientUsername || targetUserId);
        if (u) targetUserId = u.id;
      }
      if (targetUserId === recipientId && (targetUserId.toUpperCase().startsWith('USER-') || payload.recipientPrivateId)) {
        const u = await getUserByPrivateId(payload.recipientPrivateId || targetUserId);
        if (u) targetUserId = u.id;
      }
    }

    let isDelivered = false;
    if (targetUserId) {
      isDelivered = sendToUserConnections(targetUserId, receivePayload);
    }
    if (!isDelivered && recipientId && recipientId !== targetUserId) {
      isDelivered = sendToUserConnections(recipientId, receivePayload);
    }
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
      let targetSenderId = senderId;
      if (targetSenderId && !targetSenderId.startsWith('usr_')) {
        const u = await getUserByUsername(payload.senderUsername || targetSenderId) || await getUserByPrivateId(payload.senderPrivateId || targetSenderId);
        if (u) targetSenderId = u.id;
      }
      if (targetSenderId) {
        sendToUserConnections(targetSenderId, ackPayload);
      }
      if (senderId && senderId !== targetSenderId) {
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
      let targetSenderId = senderId;
      if (targetSenderId && !targetSenderId.startsWith('usr_')) {
        const u = await getUserByUsername(payload.senderUsername || targetSenderId) || await getUserByPrivateId(payload.senderPrivateId || targetSenderId);
        if (u) targetSenderId = u.id;
      }
      if (targetSenderId) {
        sendToUserConnections(targetSenderId, ackPayload);
      }
      if (senderId && senderId !== targetSenderId) {
        sendToUserConnections(senderId, ackPayload);
      }

      let targetRecipientId = recipientId;
      if (targetRecipientId && !targetRecipientId.startsWith('usr_')) {
        const u = await getUserByUsername(payload.recipientUsername || targetRecipientId) || await getUserByPrivateId(payload.recipientPrivateId || targetRecipientId);
        if (u) targetRecipientId = u.id;
      }
      if (targetRecipientId) {
        sendToUserConnections(targetRecipientId, ackPayload);
      }
      if (recipientId && recipientId !== targetRecipientId) {
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
    let targetRecipientId = recipientId;
    if (targetRecipientId && !targetRecipientId.startsWith('usr_')) {
      const u = await getUserByUsername(payload.recipientUsername || targetRecipientId) || await getUserByPrivateId(payload.recipientPrivateId || targetRecipientId);
      if (u) targetRecipientId = u.id;
    }
    if (targetRecipientId) {
      sendToUserConnections(targetRecipientId, typingPayload);
    }
    if (recipientId && recipientId !== targetRecipientId) {
      sendToUserConnections(recipientId, typingPayload);
    }
  }
}
