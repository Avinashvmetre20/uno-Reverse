import path from 'path';
import dotenv from 'dotenv';

dotenv.config({ path: path.resolve(import.meta.dirname, '../../.env') });

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT) || 3000,
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
};

if (!env.databaseUrl) {
  throw new Error('DATABASE_URL is missing');
}

if (!env.jwtSecret) {
  throw new Error('JWT_SECRET is missing');
}

export default env;
