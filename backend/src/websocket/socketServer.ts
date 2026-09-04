import { Server as HttpServer } from 'http';
import WebSocket, { Server as WSServer } from 'ws';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { handleChatMessage } from './chatHandler';
import { handleSignaling, activeCallRooms } from './signalingHandler';
import { getUserById } from '../services/identityService';
import { getPendingUndeliveredMessagesForUser, markMessageDelivered } from '../services/chatService';

// Multi-Device Socket Connections Map: userId/guestId/username/privateId -> Set of WebSockets
export const activeUserConnections = new Map<string, Set<WebSocket>>();

export function addActiveConnection(key: string, ws: WebSocket) {
  if (!key) return;
  let set = activeUserConnections.get(key);
  if (!set) {
    set = new Set();
    activeUserConnections.set(key, set);
  }
  set.add(ws);
}

export function removeActiveConnection(key: string, ws: WebSocket) {
  if (!key) return;
  const set = activeUserConnections.get(key);
  if (set) {
    set.delete(ws);
    if (set.size === 0) {
      activeUserConnections.delete(key);
    }
  }
}

export function sendToUserConnections(key: string, messagePayload: any): boolean {
  const set = activeUserConnections.get(key);
  if (!set || set.size === 0) return false;
  let delivered = false;
  const payloadStr = typeof messagePayload === 'string' ? messagePayload : JSON.stringify(messagePayload);
  set.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN) {
      try {
        ws.send(payloadStr);
        delivered = true;
      } catch (_) {}
    }
  });
  return delivered;
}

// Map compatibility for single-socket callers in signaling handler
export const activeConnections = new Proxy(activeUserConnections, {
  get(target, prop, receiver) {
    if (prop === 'get') {
      return (key: string) => {
        const set = target.get(key);
        if (set && set.size > 0) {
          for (const ws of set) {
            if (ws.readyState === WebSocket.OPEN) return ws;
          }
        }
        return undefined;
      };
    }
    return Reflect.get(target, prop, receiver);
  }
}) as unknown as Map<string, WebSocket>;

export async function broadcastOnlineUsers() {
  const onlineUsers = [];
  const onlineUserIds = Array.from(activeUserConnections.keys());
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
  activeUserConnections.forEach((set) => {
    set.forEach((clientWs) => {
      if (clientWs.readyState === WebSocket.OPEN) {
        clientWs.send(payload);
      }
    });
  });
}

export function initWebSocketServer(server: HttpServer) {
  const wss = new WSServer({ server, path: '/ws' });

  wss.on('connection', (ws: WebSocket) => {
    let currentId: string | null = null;
    let registeredKeys: string[] = [];

    const registerKey = (key: string) => {
      if (!key) return;
      addActiveConnection(key, ws);
      if (!registeredKeys.includes(key)) {
        registeredKeys.push(key);
      }
    };

    ws.on('message', async (messageData: WebSocket.RawData) => {
      try {
        const payload = JSON.parse(messageData.toString());
        const { type, token } = payload;

        // Authentication handshake
        if (type === 'auth') {
          let currentUserId: string | null = null;

          if (token && typeof token === 'string') {
            try {
              const decoded: any = jwt.verify(token, config.jwtSecret);
              currentUserId = decoded.userId;
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
            registerKey(dbUser.id);
            if (dbUser.username) {
              const cleanUname = dbUser.username.toLowerCase().replace(/^@/, '');
              registerKey(cleanUname);
              registerKey(`@${cleanUname}`);
            }
            if (dbUser.privateId) {
              registerKey(dbUser.privateId.toUpperCase());
              registerKey(dbUser.privateId.toLowerCase());
            }

            ws.send(JSON.stringify({ type: 'auth_ack', success: true, userId: dbUser.id }));
            console.log(`[WebSocket] User authenticated successfully: ${dbUser.id} (@${dbUser.username})`);
            
            // Deliver pending offline messages automatically
            try {
              const pendingMsgs = await getPendingUndeliveredMessagesForUser(dbUser.id);
              for (const pendingMsg of pendingMsgs) {
                ws.send(JSON.stringify({
                  type: 'chat_receive',
                  message: pendingMsg
                }));
                await markMessageDelivered(pendingMsg.id);
              }
            } catch (err: any) {
              console.error('[WebSocket] Failed to deliver pending messages:', err.message);
            }

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
            registerKey(currentId);
            ws.send(JSON.stringify({ type: 'guest_ack', guestId: currentId }));
          }
          return;
        }

        // Handle WebRTC Signaling (Allow public call join & signaling)
        if (type.startsWith('call_') || type === 'ice_candidate' || type === 'media_toggle' || type === 'security_event') {
          const senderId: string = currentId || payload.senderId || payload.guestId || `usr_${Date.now()}`;
          currentId = senderId;
          registerKey(senderId);
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
          activeUserConnections.forEach((set) => {
            set.forEach((wsClient) => {
              if (wsClient !== ws && wsClient.readyState === WebSocket.OPEN) {
                wsClient.send(profilePayload);
              }
            });
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
      if (registeredKeys.length > 0) {
        for (const key of registeredKeys) {
          removeActiveConnection(key, ws);
        }
        activeCallRooms.forEach((room, callId) => {
          if (currentId && room.has(currentId)) {
            const p = room.get(currentId);
            if (p && p.ws === ws) {
              room.delete(currentId);
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
