import jwt from 'jsonwebtoken';
import env from '../../config/env.js';
import { createUser, findUserByEmail, findUserById } from './auth.repository.js';

export async function registerUser({ firstName, lastName, email, password }) {
  await createUser({ firstName, lastName, email, password });
}

export async function loginUser(email, password) {
  const user = await findUserByEmail(email);

  if (!user || user.login_password !== password) {
    const error = new Error('Invalid email or password');
    error.status = 401;
    throw error;
  }

  return jwt.sign(
    { userId: user.user_id, email: user.email, role: user.role },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn },
  );
}

export async function getProfile(userId) {
  const user = await findUserById(userId);

  if (!user) {
    const error = new Error('User not found');
    error.status = 404;
    throw error;
  }

  return {
    userId: user.user_id,
    firstName: user.first_name,
    lastName: user.last_name,
    role: user.role,
    email: user.email,
    mobileNumber: user.mobile_number,
    dateOfBirth: user.date_of_birth,
    gender: user.gender,
    avatarUrl: user.avatar_url,
    status: user.status,
    isEmailVerified: user.is_email_verified,
    isMobileVerified: user.is_mobile_verified,
    lastLoginAt: user.last_login_at,
    createdAt: user.created_at,
  };
}
