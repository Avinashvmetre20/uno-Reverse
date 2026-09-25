import env from '../../config/env.js';
import { getProfile, loginUser, logoutSession, refreshSession, registerUser } from './auth.service.js';

function fail(res, error, fallback) {
  const status = error.status || 500;
  res.status(status).json({
    message: status === 500 ? fallback : error.message,
    code: status === 500 ? 'SERVER_ERROR' : error.code,
  });
}

function platformOf(req) {
  const value = req.get('x-client-platform');
  if (typeof value !== 'string') {
    return null;
  }
  const platform = value.trim().toLowerCase();
  if (!platform || platform.length > 32) {
    return null;
  }
  return platform;
}

export async function register(req, res) {
  const firstName = typeof req.body?.firstName === 'string' ? req.body.firstName.trim() : '';
  const lastName = typeof req.body?.lastName === 'string' ? req.body.lastName.trim() : '';
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = typeof req.body?.password === 'string' ? req.body.password : '';

  if (!firstName || !lastName || !email || !password) {
    res.status(400).json({
      message: 'firstName, lastName, email and password are required',
      code: 'VALIDATION_ERROR',
    });
    return;
  }

  try {
    await registerUser({ firstName, lastName, email, password });
    res.status(201).json({ message: 'Registered' });
  } catch (error) {
    fail(res, error, 'Unable to register');
  }
}

export async function login(req, res) {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = typeof req.body?.password === 'string' ? req.body.password : '';

  if (!email || !password) {
    res.status(400).json({
      message: 'email and password are required',
      code: 'VALIDATION_ERROR',
    });
    return;
  }

  try {
    const session = await loginUser(email, password, platformOf(req));
    res.status(200).json({
      token: session.accessToken,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresIn: env.accessTokenTtlSeconds,
      sessionId: session.sessionId,
    });
  } catch (error) {
    fail(res, error, 'Unable to login');
  }
}

export async function refresh(req, res) {
  const refreshToken = typeof req.body?.refreshToken === 'string' ? req.body.refreshToken : '';

  if (!refreshToken) {
    res.status(400).json({
      message: 'refreshToken is required',
      code: 'VALIDATION_ERROR',
    });
    return;
  }

  try {
    const session = await refreshSession(refreshToken);
    res.status(200).json({
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresIn: env.accessTokenTtlSeconds,
      sessionId: session.sessionId,
    });
  } catch (error) {
    fail(res, error, 'Unable to refresh session');
  }
}

export async function logout(req, res) {
  const refreshToken = typeof req.body?.refreshToken === 'string' ? req.body.refreshToken : '';

  if (!refreshToken) {
    res.status(400).json({
      message: 'refreshToken is required',
      code: 'VALIDATION_ERROR',
    });
    return;
  }

  try {
    await logoutSession(refreshToken);
    res.status(200).json({ message: 'Logged out' });
  } catch (error) {
    fail(res, error, 'Unable to logout');
  }
}

export async function profile(req, res) {
  try {
    const user = await getProfile(req.user.userId);
    res.status(200).json(user);
  } catch (error) {
    fail(res, error, 'Unable to load profile');
  }
}
