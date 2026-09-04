import dotenv from 'dotenv';
dotenv.config();

const isProduction = process.env.NODE_ENV === 'production';

// ---------------------------------------------------------------------------
// Production Secret Guard
// In production, critical secrets MUST be set explicitly.
// The application will refuse to start with insecure fallback values.
// ---------------------------------------------------------------------------
function requireSecret(name: string, value: string | undefined, fallback: string): string {
  if (isProduction) {
    if (!value || value.trim().length === 0) {
      console.error(`[Config] FATAL: Environment variable "${name}" is required in production but is not set.`);
      process.exit(1);
    }
    if (value === fallback) {
      console.error(`[Config] FATAL: "${name}" is using a known insecure development default. Set a strong secret.`);
      process.exit(1);
    }
    if (value.length < 32) {
      console.error(`[Config] FATAL: "${name}" must be at least 32 characters. Current length: ${value.length}.`);
      process.exit(1);
    }
  }
  return value || fallback;
}

function requireVar(name: string, value: string | undefined, fallback: string): string {
  if (isProduction && (!value || value.trim().length === 0)) {
    console.error(`[Config] FATAL: Environment variable "${name}" is required in production but is not set.`);
    process.exit(1);
  }
  return value || fallback;
}

// Validate CORS — reject wildcard '*' in production
const rawCorsOrigin = process.env.CORS_ORIGIN;
if (isProduction && (!rawCorsOrigin || rawCorsOrigin.trim() === '*')) {
  console.error('[Config] FATAL: CORS_ORIGIN must be set to a specific origin in production. Wildcard "*" is not permitted.');
  process.exit(1);
}

const DEV_JWT_FALLBACK   = 'super-secret-privacy-jwt-key-32bytes-long!';
const DEV_TURN_FALLBACK  = 'turn-secret-key-ourspace';
const DEV_DB_FALLBACK    = 'postgresql://postgres:postgres@localhost:5432/private_chat_db';

export const config = {
  port: parseInt(process.env.PORT || '4000', 10),
  env: process.env.NODE_ENV || 'development',

  jwtSecret: requireSecret('JWT_SECRET', process.env.JWT_SECRET, DEV_JWT_FALLBACK),

  databaseUrl: requireVar('DATABASE_URL', process.env.DATABASE_URL, DEV_DB_FALLBACK),

  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',

  // Production: explicitly required origin. Development: permissive default.
  corsOrigin: isProduction
    ? rawCorsOrigin!
    : (rawCorsOrigin || '*'),

  turnServer: {
    urls:       process.env.TURN_URL       || 'stun:stun.l.google.com:19302',
    urlsTls:    process.env.TURN_URL_TLS   || '',
    username:   process.env.TURN_USERNAME  || '',
    credential: process.env.TURN_CREDENTIAL || '',
    // TURN_SECRET: fall back to JWT_SECRET only in development for convenience
    secret: requireSecret(
      'TURN_SECRET',
      process.env.TURN_SECRET,
      isProduction ? '' : (process.env.JWT_SECRET || DEV_TURN_FALLBACK)
    ),
  }
};
