import bcrypt from 'bcryptjs';

export function isPasswordHash(value) {
  return typeof value === 'string' && value.startsWith('$2');
}

export function hashPassword(password) {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password, stored) {
  if (isPasswordHash(stored)) {
    return bcrypt.compare(password, stored);
  }

  return stored === password;
}
