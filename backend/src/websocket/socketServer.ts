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
          let currentUserId: string | null = null;
          let currentUsername: string | null = null;
          let currentPrivateId: string | null = null;

          if (token && typeof token === 'string') {
            try {
              const decoded: any = jwt.verify(token, config.jwtSecret);
              currentUserId = decoded.userId;
              currentUsername = decoded.username;
              currentPrivateId = decoded.privateId;
            } catch (err) {
              console.log(`[WebSocket] Token verification failed:`, err);
            }
          }

          if (currentUserId) {
            const dbUser = await getUserById(currentUserId);
            if (!dbUser) {
              console.log(`[WebSocket] Auth rejected: User ${currentUserId} no longer exists in DB.`);
              ws.send(JSON.stringify({ type: 'account_deleted', success: false, error: 'ACCOUNT_DELETED' }));
              ws.send(JSON.stringify({ type: 'auth_ack', success: false, error: 'ACCOUNT_DELETED' }));
              try { ws.close(); } catch (_) {}
              return;
            }

            currentId = dbUser.id;
            activeConnections.set(dbUser.id, ws);
            if (dbUser.username) {
              const cleanUname = dbUser.username.toLowerCase().replace(/^@/, '');
              activeConnections.set(cleanUname, ws);
              activeConnections.set(`@${cleanUname}`, ws);
            }
            if (dbUser.privateId) {
              activeConnections.set(dbUser.privateId.toUpperCase(), ws);
              activeConnections.set(dbUser.privateId.toLowerCase(), ws);
            }
            ws.send(JSON.stringify({ type: 'auth_ack', success: true, userId: dbUser.id }));
            console.log(`[WebSocket] User authenticated successfully: ${dbUser.id} (@${dbUser.username})`);
            await broadcastOnlineUsers();
          } else {
            console.log(`[WebSocket] Auth attempt rejected: Invalid or missing token.`);
            ws.send(JSON.stringify({ type: 'auth_ack', success: false, error: 'UNAUTHORIZED: Valid token required' }));
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
          const senderId: string = currentId || payload.senderId || payload.guestId || `usr_${Date.now()}`;
          currentId = senderId;
          activeConnections.set(senderId, ws);
          payload.senderId = senderId; // Force identity
          handleSignaling(ws, payload, activeConnections);
          return;
        }

        // Enforce Authentication for chat messages
        if (!currentId) {
          ws.send(JSON.stringify({ type: 'error', error: 'UNAUTHORIZED: WebSocket handshake required' }));
          return;
        }

        // Handle Profile picture updates across connected users
        if (type === 'profile_update') {
          const profilePayload = JSON.stringify({
            type: 'profile_update',
            userId: currentId,
            senderUsername: payload.senderUsername,
            profileImage: payload.profileImage
          });
          activeConnections.forEach((wsClient) => {
            if (wsClient !== ws && wsClient.readyState === WebSocket.OPEN) {
              wsClient.send(profilePayload);
            }
          });
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
        if (activeConnections.get(currentId) === ws) {
          activeConnections.delete(currentId);
        }
        activeCallRooms.forEach((room, callId) => {
          if (room.has(currentId!)) {
            const p = room.get(currentId!);
            if (p && p.ws === ws) {
              room.delete(currentId!);
              if (room.size === 0) {
                activeCallRooms.delete(callId);
              }
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
