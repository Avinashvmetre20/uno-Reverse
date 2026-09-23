import jwt from 'jsonwebtoken';
import env from '../config/env.js';

export function authenticate(req, res, next) {
  const header = req.headers.authorization;
  const token = header?.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    res.status(401).json({ message: 'Token is required' });
    return;
  }

  try {
    req.user = jwt.verify(token, env.jwtSecret);
    next();
  } catch {
    res.status(401).json({ message: 'Invalid or expired token' });
  }
}
