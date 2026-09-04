import rateLimit from 'express-rate-limit';

// ---------------------------------------------------------------------------
// Global API Rate Limiter
// Applied to all routes. Protects against broad abuse.
// ---------------------------------------------------------------------------
export const apiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 200,                    // 200 requests per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please try again later.' }
});

// ---------------------------------------------------------------------------
// Authentication Rate Limiter
// Applies to /api/auth/login, /register, /recover
// Prevents brute-force credential attacks.
// ---------------------------------------------------------------------------
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 20,                     // 20 attempts per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many authentication attempts. Please try again later.' }
});

// ---------------------------------------------------------------------------
// TURN Credential Rate Limiter
// Prevents TURN credential farming.
// Keyed by authenticated userId when available, IP otherwise.
// ---------------------------------------------------------------------------
export const turnRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 10,                     // 10 TURN credential requests per window
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req: any) => req.user?.userId || req.ip,
  message: { error: 'Too many TURN credential requests. Please wait before retrying.' }
});
