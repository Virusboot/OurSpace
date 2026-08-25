import { Server as HttpServer } from 'http';
import WebSocket, { Server as WSServer } from 'ws';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { handleChatMessage } from './chatHandler';
import { handleSignaling, activeCallRooms } from './signalingHandler';
import { getUserById } from '../services/identityService';

export const activeConnections = new Map<string, WebSocket>(); // userId/guestId -> WebSocket

export async function broadcastOnlineUsers() {
  const onlineUsers = [];
  const onlineUserIds = Array.from(activeConnections.keys());
  for (const id of onlineUserIds) {
    if (id.startsWith('usr_')) {
      const user = await getUserById(id);
      if (user) {
        onlineUsers.push({
          id: user.id,
          username: user.username,
          privateId: user.privateId
        });
      }
    }
  }
  const payload = JSON.stringify({
    type: 'online_users_update',
    users: onlineUsers
  });
  activeConnections.forEach((clientWs) => {
    if (clientWs.readyState === WebSocket.OPEN) {
      clientWs.send(payload);
    }
  });
}

export function initWebSocketServer(server: HttpServer) {
  const wss = new WSServer({ server, path: '/ws' });

  wss.on('connection', (ws: WebSocket, req) => {
    let currentId: string | null = null;

    ws.on('message', async (messageData: WebSocket.RawData) => {
      try {
        const payload = JSON.parse(messageData.toString());
        const { type, token, userId } = payload;

        // Authentication handshake
        if (type === 'auth') {
          try {
            const decoded: any = jwt.verify(token, config.jwtSecret);
            currentId = decoded.userId;
            if (currentId) {
              activeConnections.set(currentId, ws);
              if (decoded.username) {
                activeConnections.set(decoded.username.toLowerCase(), ws);
              }
              if (decoded.privateId) {
                activeConnections.set(decoded.privateId.toUpperCase(), ws);
              }
              ws.send(JSON.stringify({ type: 'auth_ack', success: true, userId: currentId }));
              console.log(`[WebSocket] User authenticated: ${currentId}`);
              await broadcastOnlineUsers();
            }
          } catch (err) {
            ws.send(JSON.stringify({ type: 'auth_ack', success: false, error: 'Invalid auth token' }));
          }
          return;
        }

        // Guest identification for public call links
        if (type === 'guest_register') {
          currentId = payload.guestId || `guest_${Math.random().toString(36).substring(2, 9)}`;
          if (currentId) {
            activeConnections.set(currentId, ws);
            ws.send(JSON.stringify({ type: 'guest_ack', guestId: currentId }));
          }
          return;
        }

        // Handle WebRTC Signaling (Allow public call join & signaling)
        if (type.startsWith('call_') || type === 'ice_candidate' || type === 'media_toggle' || type === 'security_event') {
          if (!currentId) {
            currentId = payload.senderId || payload.guestId || `usr_${Date.now()}`;
            activeConnections.set(currentId, ws);
          }
          payload.senderId = currentId; // Force identity
          handleSignaling(ws, payload, activeConnections);
          return;
        }

        // Enforce Authentication for chat messages
        if (!currentId) {
          ws.send(JSON.stringify({ type: 'error', error: 'UNAUTHORIZED: WebSocket handshake required' }));
          return;
        }

        // Handle Chat messages (Enforce senderId matching currentId to prevent IDOR spoofing)
        if (type.startsWith('chat_')) {
          payload.senderId = currentId; // Force authenticated identity
          await handleChatMessage(ws, payload, activeConnections);
          return;
        }

      } catch (err) {
        console.error('[WebSocket] Error processing message:', err);
      }
    });

    ws.on('close', async () => {
      if (currentId) {
        activeConnections.delete(currentId);
        // Clean up rooms
        activeCallRooms.forEach((room, callId) => {
          if (room.has(currentId!)) {
            room.delete(currentId!);
            if (room.size === 0) {
              activeCallRooms.delete(callId);
            }
          }
        });
        console.log(`[WebSocket] Client disconnected: ${currentId}`);
        await broadcastOnlineUsers();
      }
    });
  });

  console.log('[WebSocket] Server listening at /ws endpoint');
  return wss;
}
