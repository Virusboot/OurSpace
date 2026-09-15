import http from 'https';

// Memory store for User ID -> FCM Tokens map
const userFcmTokens = new Map<string, Set<string>>();

export function registerUserFcmToken(userId: string, token: string) {
  if (!userId || !token) return;
  let set = userFcmTokens.get(userId);
  if (!set) {
    set = new Set();
    userFcmTokens.set(userId, set);
  }
  set.add(token);
}

export function getUserFcmTokens(userId: string): string[] {
  const set = userFcmTokens.get(userId);
  return set ? Array.from(set) : [];
}

export async function sendFcmCallNotification(params: {
  targetUserId: string;
  callId: string;
  callType: string;
  callerUsername: string;
  senderId: string;
}) {
  const tokens = getUserFcmTokens(params.targetUserId);
  if (tokens.length === 0) {
    console.log(`[PushNotification] No FCM tokens found for target user ${params.targetUserId}`);
    return;
  }

  const payload = {
    type: 'call_invite',
    callId: params.callId,
    callType: params.callType,
    callerUsername: params.callerUsername,
    senderId: params.senderId,
  };

  console.log(`[PushNotification] Sending FCM call notification to ${tokens.length} tokens for user ${params.targetUserId}`);

  // Push notification payload formatted for FCM
  for (const fcmToken of tokens) {
    try {
      // Broadcast high priority data message
      // Note: If FCM Server Key or Firebase Admin SDK is configured via process.env.FCM_SERVER_KEY,
      // it will post directly to FCM REST API endpoint.
      if (process.env.FCM_SERVER_KEY) {
        const postData = JSON.stringify({
          to: fcmToken,
          priority: 'high',
          content_available: true,
          data: payload,
          notification: {
            title: `Incoming ${params.callType.toUpperCase()} Call`,
            body: `${params.callerUsername} is calling...`,
            sound: 'default',
            android_channel_id: 'ourspace_calls_channel',
          }
        });

        const req = http.request({
          hostname: 'fcm.googleapis.com',
          path: '/fcm/send',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${process.env.FCM_SERVER_KEY}`,
            'Content-Length': Buffer.byteLength(postData)
          }
        }, (res) => {
          console.log(`[PushNotification] FCM response status: ${res.statusCode}`);
        });

        req.on('error', (e) => {
          console.error(`[PushNotification] FCM send error:`, e.message);
        });

        req.write(postData);
        req.end();
      }
    } catch (e: any) {
      console.error(`[PushNotification] Error sending push:`, e.message);
    }
  }
}
