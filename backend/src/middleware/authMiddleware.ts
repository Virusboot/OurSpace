import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { getUserById } from '../services/identityService';

export interface AuthRequest extends Request {
  user?: {
    userId: string;
    privateId: string;
    username: string;
  };
}

export function authenticateToken(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, config.jwtSecret, { algorithms: ['HS256'] }, async (err, decoded: any) => {
    if (err || !decoded || typeof decoded !== 'object' || !decoded.userId) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    try {
      const dbUser = await getUserById(decoded.userId);
      if (!dbUser) {
        return res.status(401).json({ error: 'User account no longer exists or token revoked' });
      }

      req.user = {
        userId: dbUser.id,
        privateId: dbUser.privateId,
        username: dbUser.username,
      };
      next();
    } catch (_) {
      return res.status(500).json({ error: 'Authentication verification failed' });
    }
  });
}
