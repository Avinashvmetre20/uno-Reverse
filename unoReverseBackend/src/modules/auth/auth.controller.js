import logger from '../../config/logger.js';
import { getProfile, loginUser, registerUser } from './auth.service.js';

export async function register(req, res) {
  const firstName = typeof req.body?.firstName === 'string' ? req.body.firstName.trim() : '';
  const lastName = typeof req.body?.lastName === 'string' ? req.body.lastName.trim() : '';
  const email = typeof req.body?.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = typeof req.body?.password === 'string' ? req.body.password : '';

  if (!firstName || !lastName || !email || !password) {
    res.status(400).json({ message: 'firstName, lastName, email and password are required' });
    return;
  }

  try {
    await registerUser({ firstName, lastName, email, password });
    res.status(201).json({ message: 'Registered' });
  } catch (error) {
    const status = error.status || 500;

    if (status === 500) {
      logger.error({ code: error.code }, 'register failed');
    }

    res.status(status).json({
      message: status === 500 ? 'Unable to register' : error.message,
    });
  }
}

export async function login(req, res) {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim() : '';
  const password = typeof req.body?.password === 'string' ? req.body.password : '';

  if (!email || !password) {
    res.status(400).json({ message: 'email and password are required' });
    return;
  }

  try {
    const token = await loginUser(email, password);
    res.status(200).json({ token });
  } catch (error) {
    const status = error.status || 500;

    if (status === 500) {
      logger.error({ code: error.code }, 'login failed');
    }

    res.status(status).json({
      message: status === 500 ? 'Unable to login' : error.message,
    });
  }
}

export async function profile(req, res) {
  try {
    const user = await getProfile(req.user.userId);
    res.status(200).json(user);
  } catch (error) {
    const status = error.status || 500;

    if (status === 500) {
      logger.error({ code: error.code }, 'profile failed');
    }

    res.status(status).json({
      message: status === 500 ? 'Unable to load profile' : error.message,
    });
  }
}
