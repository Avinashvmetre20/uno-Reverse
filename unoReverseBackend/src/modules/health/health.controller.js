import pool from '../../database/connection.js';
import logger from '../../config/logger.js';

export async function getHealth(req, res) {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({
      status: 'ok',
      database: 'up',
    });
  } catch (error) {
    logger.error({ code: error.code }, 'database health check failed');
    res.status(503).json({
      status: 'error',
      database: 'down',
    });
  }
}
