import app from './app.js';
import env from './config/env.js';
import logger from './config/logger.js';
import pool from './database/connection.js';

const server = app.listen(env.port, () => {
  logger.info({ port: env.port }, 'server listening');
});

async function shutdown() {
  server.close();
  await pool.end();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
