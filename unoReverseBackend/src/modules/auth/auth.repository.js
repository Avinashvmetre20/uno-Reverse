import pool from '../../database/connection.js';

export async function createUser({ firstName, lastName, email, password }) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const existing = await client.query(
      `SELECT user_id
       FROM user_master
       WHERE lower(email) = lower($1)
       LIMIT 1`,
      [email],
    );

    if (existing.rows.length > 0) {
      const error = new Error('Email is already registered');
      error.status = 409;
      throw error;
    }

    const created = await client.query(
      `INSERT INTO user_master (first_name, last_name, email)
       VALUES ($1, $2, $3)
       RETURNING user_id`,
      [firstName, lastName, email],
    );

    await client.query(
      `INSERT INTO user_credentials (user_id, login_password)
       VALUES ($1, $2)`,
      [created.rows[0].user_id, password],
    );

    await client.query('COMMIT');
    return created.rows[0].user_id;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function findUserByEmail(email) {
  const result = await pool.query(
    `SELECT u.user_id, u.email, u.role, c.login_password
     FROM user_master u
     JOIN user_credentials c ON c.user_id = u.user_id
     WHERE lower(u.email) = lower($1)
     LIMIT 1`,
    [email],
  );

  return result.rows[0] || null;
}

export async function findUserById(userId) {
  const result = await pool.query(
    `SELECT user_id, first_name, last_name, role, email, mobile_number,
            date_of_birth, gender, avatar_url, is_active,
            is_email_verified, is_mobile_verified, last_login_at, created_at
     FROM user_master
     WHERE user_id = $1
     LIMIT 1`,
    [userId],
  );

  return result.rows[0] || null;
}
