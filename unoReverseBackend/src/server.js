import app from './app.js';
import env from './config/env.js';
import pool from './database/connection.js';

const server = app.listen(env.port, () => {
  console.log(`server listening on port ${env.port}`);
});

async function shutdown() {
  server.close();
  await pool.end();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
