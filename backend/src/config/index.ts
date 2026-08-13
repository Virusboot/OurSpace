import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: process.env.PORT || 4000,
  env: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'super-secret-privacy-jwt-key-32bytes-long!',
  databaseUrl: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/private_chat_db',
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  turnServer: {
    urls: process.env.TURN_URL || 'stun:stun.l.google.com:19302',
    username: process.env.TURN_USERNAME || '',
    credential: process.env.TURN_CREDENTIAL || ''
  }
};
