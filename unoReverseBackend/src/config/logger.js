import pino from 'pino';
import env from './env.js';

const logger = pino({
  level: env.nodeEnv === 'production' ? 'info' : 'debug',
});

export default logger;
