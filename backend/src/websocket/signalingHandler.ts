import WebSocket from 'ws';

// In-memory call room participants registry (callId -> Map of participantId -> { ws, role, nickname })
export const activeCallRooms = new Map<string, Map<string, { ws: WebSocket; role: string; nickname?: string }>>();

export function handleSignaling(
  ws: WebSocket,
  payload: any,
  activeConnections: Map<string, WebSocket>
) {
  const { type, callId, targetId, senderId, sdp, candidate, callType, nickname, mediaState } = payload;

  if (type === 'call_join') {
    // Participant joining a call room (native app or web guest)
    let room = activeCallRooms.get(callId);
    if (!room) {
      room = new Map();
      activeCallRooms.set(callId, room);
    }

    const participantId = senderId || `guest_${Math.random().toString(36).substring(2, 9)}`;
    room.set(participantId, { ws, role: senderId ? 'user' : 'guest', nickname });

    // Notify other participants in room
    room.forEach((participant, pid) => {
      if (pid !== participantId && participant.ws.readyState === WebSocket.OPEN) {
        participant.ws.send(JSON.stringify({
          type: 'participant_joined',
          callId,
          participantId,
          nickname
        }));
      }
    });

    ws.send(JSON.stringify({
      type: 'call_joined_ack',
      callId,
      assignedParticipantId: participantId,
      existingParticipants: Array.from(room.keys()).filter(id => id !== participantId)
    }));

  } else if (type === 'call_invite') {
    let targetWs: WebSocket | undefined;
    if (payload.targetUserId) {
      targetWs = activeConnections.get(payload.targetUserId);
    }
    if (!targetWs && payload.targetUsername) {
      const rawUname = payload.targetUsername.toLowerCase();
      const cleanUname = rawUname.replace(/^@/, '');
      targetWs = activeConnections.get(rawUname) ||
                 activeConnections.get(cleanUname) ||
                 activeConnections.get(`@${cleanUname}`);
    }
    if (!targetWs && payload.targetPrivateId) {
      targetWs = activeConnections.get(payload.targetPrivateId.toUpperCase()) ||
                 activeConnections.get(payload.targetPrivateId.toLowerCase());
    }

    if (targetWs && targetWs.readyState === WebSocket.OPEN) {
      targetWs.send(JSON.stringify({
        type: 'call_invite',
        callId: payload.callId,
        callType: payload.callType,
        token: payload.token,
        senderId: payload.senderId,
        senderUsername: payload.callerUsername || payload.senderUsername || '@peer',
        senderProfileImage: payload.senderProfileImage,
      }));
      console.log(`[Signaling] call_invite delivered for callId ${payload.callId}`);
    } else {
      console.log(`[Signaling] Target user offline or not found for call_invite: ${payload.targetUsername || payload.targetUserId}`);
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'call_failed',
          callId: payload.callId,
          reason: 'recipient_offline',
          targetUsername: payload.targetUsername || 'User'
        }));
      }
    }
  } else if (type === 'call_offer' || type === 'call_answer' || type === 'ice_candidate' || type === 'media_toggle') {
    let routed = false;
    if (targetId) {
      const targetWs = activeConnections.get(targetId);
      if (targetWs && targetWs.readyState === WebSocket.OPEN) {
        targetWs.send(JSON.stringify(payload));
        routed = true;
      } else {
        const room = activeCallRooms.get(callId);
        if (room && room.has(targetId)) {
          const targetObj = room.get(targetId)!;
          if (targetObj.ws.readyState === WebSocket.OPEN) {
            targetObj.ws.send(JSON.stringify(payload));
            routed = true;
          }
        }
      }
    }
    
    if (!routed) {
      // Broadcast to room members except sender
      const room = activeCallRooms.get(callId);
      if (room) {
        room.forEach((participant) => {
          if (participant.ws !== ws && participant.ws.readyState === WebSocket.OPEN) {
            participant.ws.send(JSON.stringify(payload));
          }
        });
      }
    }
  } else if (type === 'call_hangup') {
    const room = activeCallRooms.get(callId);
    if (room) {
      room.forEach((participant) => {
        if (participant.ws !== ws && participant.ws.readyState === WebSocket.OPEN) {
          participant.ws.send(JSON.stringify({
            type: 'call_ended',
            callId,
            reason: 'Participant left call'
          }));
        }
      });
      activeCallRooms.delete(callId);
    }
  } else if (type === 'security_event') {
    // Screenshot / screen recording alert during active call
    const room = activeCallRooms.get(callId);
    if (room) {
      room.forEach((participant) => {
        if (participant.ws !== ws && participant.ws.readyState === WebSocket.OPEN) {
          participant.ws.send(JSON.stringify({
            type: 'security_alert',
            event: payload.event || 'screen_capture_detected',
            message: 'Participant device triggered privacy protection overlay.'
          }));
        }
      });
    }
  }
}
