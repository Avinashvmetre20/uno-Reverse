import {
  createSession,
  createUser,
  findUserByEmail,
  findUserById,
  rotateRefreshToken,
  revokeByRefreshToken,
  touchLastLogin,
  updatePasswordHash,
} from './auth.repository.js';
import { hashPassword, isPasswordHash, verifyPassword } from './password.js';
import { signAccessToken } from './tokens.js';

function httpError(status, message, code) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function issue(user, session) {
  return {
    accessToken: signAccessToken({
      userId: user.userId ?? user.user_id,
      email: user.email,
      role: user.role,
      sessionId: session.sessionId,
    }),
    refreshToken: session.refreshToken,
    sessionId: session.sessionId,
  };
}

export async function registerUser({ firstName, lastName, email, password }) {
  const passwordHash = await hashPassword(password);
  await createUser({ firstName, lastName, email, password: passwordHash });
}

export async function loginUser(email, password, platform) {
  const user = await findUserByEmail(email);

  if (!user || !(await verifyPassword(password, user.login_password))) {
    throw httpError(401, 'Invalid email or password', 'INVALID_CREDENTIALS');
  }

  if (!isPasswordHash(user.login_password)) {
    await updatePasswordHash(user.user_id, await hashPassword(password));
  }

  const session = await createSession({ userId: user.user_id, platform });
  await touchLastLogin(user.user_id);

  return issue(
    { userId: user.user_id, email: user.email, role: user.role },
    session,
  );
}

export async function refreshSession(refreshToken) {
  const rotated = await rotateRefreshToken(refreshToken);
  return issue(
    { userId: rotated.userId, email: rotated.email, role: rotated.role },
    rotated,
  );
}

export async function logoutSession(refreshToken) {
  await revokeByRefreshToken(refreshToken);
}

export async function getProfile(userId) {
  const user = await findUserById(userId);

  if (!user) {
    throw httpError(404, 'User not found', 'USER_NOT_FOUND');
  }

  const banks = Array.isArray(user.banks) ? user.banks : [];

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
    isActive: user.is_active,
    isEmailVerified: user.is_email_verified,
    isMobileVerified: user.is_mobile_verified,
    lastLoginAt: user.last_login_at,
    createdAt: user.created_at,
    bankNames: banks.map((bank) => bank.bankName).filter(Boolean),
    banks,
    cardCount: user.card_count ?? 0,
    transactionCount: user.transaction_count ?? 0,
    totalBalance: user.total_balance,
  };
}
