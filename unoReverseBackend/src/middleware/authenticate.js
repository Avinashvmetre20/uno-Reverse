import jwt from 'jsonwebtoken';
import env from '../config/env.js';
import { isSessionActive } from '../modules/auth/auth.repository.js';

export async function authenticate(req, res, next) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    res.status(401).json({
      message: 'Your session has expired. Please log in again.',
      code: 'ACCESS_INVALID',
    });
    return;
  }

  try {
    const payload = jwt.verify(token, env.jwtSecret);

    if (!payload.sessionId || !(await isSessionActive(payload.sessionId))) {
      res.status(401).json({
        message: 'Your session has expired. Please log in again.',
        code: 'SESSION_REVOKED',
      });
      return;
    }

    req.user = payload;
    next();
  } catch (error) {
    const expired = error?.name === 'TokenExpiredError';
    res.status(401).json({
      message: 'Your session has expired. Please log in again.',
      code: expired ? 'ACCESS_EXPIRED' : 'ACCESS_INVALID',
    });
  }
}
