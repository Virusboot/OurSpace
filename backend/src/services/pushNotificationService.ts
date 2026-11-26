import https from 'https';
import crypto from 'crypto';
import { isPgActive, getPgPool } from '../db';

// Memory store for User ID -> FCM Tokens map (backed by PostgreSQL users.fcm_token)
const userFcmTokens = new Map<string, Set<string>>();
let cachedAccessToken: { token: string; expiresAt: number } | null = null;

export function registerUserFcmToken(userId: string, token: string) {
  if (!userId || !token) return;
  let set = userFcmTokens.get(userId);
  if (!set) {
    set = new Set();
    userFcmTokens.set(userId, set);
  }
  set.add(token);

  if (isPgActive()) {
    const pool = getPgPool();
    pool?.query('UPDATE users SET fcm_token = $1 WHERE id = $2', [token, userId]).catch(() => {});
  }
}

export async function getUserFcmTokens(userId: string): Promise<string[]> {
  const set = userFcmTokens.get(userId);
  if (set && set.size > 0) return Array.from(set);

  if (isPgActive()) {
    try {
      const pool = getPgPool();
      const res = await pool?.query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
      const dbToken = res?.rows[0]?.fcm_token;
      if (dbToken && typeof dbToken === 'string' && dbToken.trim().length > 0) {
        registerUserFcmToken(userId, dbToken.trim());
        return [dbToken.trim()];
      }
    } catch (_) {}
  }
  return [];
}

async function getFcmV1AccessToken(sa: { client_email: string; private_key: string }): Promise<string | null> {
  if (cachedAccessToken && Date.now() < cachedAccessToken.expiresAt - 60000) {
    return cachedAccessToken.token;
  }
  try {
    const now = Math.floor(Date.now() / 1000);
    const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
    const claim = Buffer.from(JSON.stringify({
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    })).toString('base64url');

    const signInput = `${header}.${claim}`;
    const signer = crypto.createSign('RSA-SHA256');
    signer.update(signInput);
    const signature = signer.sign(sa.private_key, 'base64url');
    const jwtAssertion = `${signInput}.${signature}`;

    const body = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwtAssertion}`;
    const tokenRes: any = await new Promise((resolve, reject) => {
      const req = https.request({
        hostname: 'oauth2.googleapis.com',
        path: '/token',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(body),
        },
      }, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
        });
      });
      req.on('error', reject);
      req.write(body);
      req.end();
    });

    if (tokenRes?.access_token) {
      cachedAccessToken = {
        token: tokenRes.access_token,
        expiresAt: Date.now() + (Number(tokenRes.expires_in || 3600) * 1000),
      };
      return cachedAccessToken.token;
    }
  } catch (err: any) {
    console.error('[PushNotification] OAuth2 token error:', err?.message || err);
  }
  return null;
}

export async function sendFcmCallNotification(params: {
  targetUserId: string;
  callId: string;
  callType: string;
  callerUsername: string;
  senderId: string;
}) {
  const tokens = await getUserFcmTokens(params.targetUserId);
  if (tokens.length === 0) {
    console.log(`[PushNotification] No FCM tokens found for target user ${params.targetUserId}`);
    return;
  }

  const payload = {
    type: 'call_invite',
    callId: String(params.callId),
    callType: String(params.callType),
    callerUsername: String(params.callerUsername),
    senderId: String(params.senderId),
  };

  console.log(`[PushNotification] Sending FCM call notification to ${tokens.length} token(s) for user ${params.targetUserId}`);

  // Prefer FCM HTTP v1 via FIREBASE_SERVICE_ACCOUNT_JSON
  const saRaw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (saRaw && saRaw.trim().startsWith('{')) {
    try {
      const sa = JSON.parse(saRaw);
      const accessToken = await getFcmV1AccessToken(sa);
      if (accessToken && sa.project_id) {
        for (const fcmToken of tokens) {
          const postData = JSON.stringify({
            message: {
              token: fcmToken,
              data: payload,
              android: {
                priority: 'high',
                notification: {
                  title: `Incoming ${params.callType.toUpperCase()} Call`,
                  body: `${params.callerUsername} is calling...`,
                  channel_id: 'ourspace_calls_channel',
                  sound: 'default',
                },
              },
            },
          });
          const req = https.request({
            hostname: 'fcm.googleapis.com',
            path: `/v1/projects/${sa.project_id}/messages:send`,
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${accessToken}`,
              'Content-Length': Buffer.byteLength(postData),
            },
          }, (res) => {
            console.log(`[PushNotification] FCM v1 status: ${res.statusCode}`);
          });
          req.on('error', (e) => console.error('[PushNotification] FCM v1 error:', e.message));
          req.write(postData);
          req.end();
        }
        return;
      }
    } catch (e: any) {
      console.error('[PushNotification] Invalid FIREBASE_SERVICE_ACCOUNT_JSON:', e?.message);
    }
  }

  // Legacy fallback if FCM_SERVER_KEY is explicitly configured
  if (process.env.FCM_SERVER_KEY) {
    for (const fcmToken of tokens) {
      try {
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

        const req = https.request({
          hostname: 'fcm.googleapis.com',
          path: '/fcm/send',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${process.env.FCM_SERVER_KEY}`,
            'Content-Length': Buffer.byteLength(postData)
          }
        }, (res) => {
          console.log(`[PushNotification] FCM legacy status: ${res.statusCode}`);
        });

        req.on('error', (e) => console.error('[PushNotification] FCM send error:', e.message));
        req.write(postData);
        req.end();
      } catch (e: any) {
        console.error('[PushNotification] Error sending push:', e.message);
      }
    }
  }
}
