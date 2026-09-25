import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import env from '../../config/env.js';

export function newId() {
  return crypto.randomUUID();
}

export function newRefreshToken() {
  return crypto.randomBytes(32).toString('base64url');
}

export function hashRefreshToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function signAccessToken({ userId, email, role, sessionId }) {
  return jwt.sign(
    { userId, email, role, sessionId },
    env.jwtSecret,
    { expiresIn: env.accessTokenTtlSeconds },
  );
}

export function refreshExpiryDate() {
  return new Date(Date.now() + env.refreshTokenTtlDays * 24 * 60 * 60 * 1000);
}
