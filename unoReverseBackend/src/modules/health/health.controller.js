import pool from '../../database/connection.js';

export async function getHealth(req, res) {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({
      status: 'ok',
      database: 'up',
    });
  } catch {
    res.status(503).json({
      status: 'error',
      database: 'down',
      message: 'Database is down',
    });
  }
}
