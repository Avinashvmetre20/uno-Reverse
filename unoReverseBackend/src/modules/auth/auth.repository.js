import pool from '../../database/connection.js';
import { hashRefreshToken, newId, newRefreshToken, refreshExpiryDate } from './tokens.js';

let schemaReady;

export function ensureAuthSchema() {
  schemaReady ??= pool.query(`
    CREATE TABLE IF NOT EXISTS user_session (
        session_id          UUID PRIMARY KEY,
        user_id             INTEGER NOT NULL,
        token_family_id     UUID NOT NULL,
        platform            VARCHAR(32),
        created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        last_used_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        expires_at          TIMESTAMPTZ NOT NULL,
        revoked_at          TIMESTAMPTZ,
        revocation_reason   VARCHAR(64),
        CONSTRAINT fk_user_session_user
            FOREIGN KEY (user_id)
            REFERENCES user_master (user_id)
            ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_user_session_family
        ON user_session (token_family_id);

    CREATE TABLE IF NOT EXISTS user_session_refresh (
        refresh_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        session_id          UUID NOT NULL,
        token_family_id     UUID NOT NULL,
        refresh_token_hash  TEXT NOT NULL UNIQUE,
        created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        replaced_at         TIMESTAMPTZ,
        expires_at          TIMESTAMPTZ NOT NULL,
        CONSTRAINT fk_user_session_refresh_session
            FOREIGN KEY (session_id)
            REFERENCES user_session (session_id)
            ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_user_session_refresh_family
        ON user_session_refresh (token_family_id);
  `);

  return schemaReady;
}

function httpError(status, message, code) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

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
      throw httpError(409, 'Email is already registered', 'EMAIL_TAKEN');
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

export async function updatePasswordHash(userId, passwordHash) {
  await pool.query(
    `UPDATE user_credentials
     SET login_password = $2, password_changed_at = NOW(), updated_at = NOW()
     WHERE user_id = $1`,
    [userId, passwordHash],
  );
}

export async function touchLastLogin(userId) {
  await pool.query(
    `UPDATE user_master
     SET last_login_at = NOW(), updated_at = NOW()
     WHERE user_id = $1`,
    [userId],
  );
}

export async function findUserById(userId) {
  const result = await pool.query(
    `SELECT u.user_id, u.first_name, u.last_name, u.role, u.email, u.mobile_number,
            u.date_of_birth, u.gender, u.avatar_url, u.is_active,
            u.is_email_verified, u.is_mobile_verified, u.last_login_at, u.created_at,
            COALESCE(
              (
                SELECT json_agg(
                  json_build_object(
                    'bankId', bm.bank_id,
                    'bankName', bm.bank_name,
                    'accountType', bm.account_type,
                    'accountLast4', bm.account_last_4,
                    'balance', bm.balance
                  )
                  ORDER BY bm.bank_name ASC
                )
                FROM bank_master bm
                WHERE bm.user_id = u.user_id AND bm.is_active = TRUE
              ),
              '[]'::json
            ) AS banks,
            (
              SELECT COUNT(*)::int
              FROM card_master cm
              WHERE cm.user_id = u.user_id AND cm.is_active = TRUE
            ) AS card_count,
            (
              SELECT COUNT(*)::int
              FROM user_transaction ut
              WHERE ut.user_id = u.user_id AND ut.is_active = TRUE
            ) AS transaction_count,
            (
              SELECT COALESCE(SUM(bm.balance), 0)
              FROM bank_master bm
              WHERE bm.user_id = u.user_id AND bm.is_active = TRUE
            ) AS total_balance
     FROM user_master u
     WHERE u.user_id = $1
     LIMIT 1`,
    [userId],
  );

  return result.rows[0] || null;
}

export async function isSessionActive(sessionId) {
  const result = await pool.query(
    `SELECT session_id
     FROM user_session
     WHERE session_id = $1
       AND revoked_at IS NULL
       AND expires_at > NOW()
     LIMIT 1`,
    [sessionId],
  );

  return result.rows.length > 0;
}

export async function createSession({ userId, platform }) {
  const sessionId = newId();
  const familyId = newId();
  const refreshToken = newRefreshToken();
  const expiresAt = refreshExpiryDate();

  await pool.query(
    `INSERT INTO user_session (session_id, user_id, token_family_id, platform, expires_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [sessionId, userId, familyId, platform, expiresAt],
  );

  await pool.query(
    `INSERT INTO user_session_refresh (session_id, token_family_id, refresh_token_hash, expires_at)
     VALUES ($1, $2, $3, $4)`,
    [sessionId, familyId, hashRefreshToken(refreshToken), expiresAt],
  );

  return { sessionId, refreshToken, expiresAt };
}

export async function rotateRefreshToken(rawToken) {
  const hash = hashRefreshToken(rawToken);
  const client = await pool.connect();
  let committed = false;

  try {
    await client.query('BEGIN');

    const found = await client.query(
      `SELECT r.refresh_id, r.session_id, r.token_family_id, r.replaced_at, r.expires_at,
              s.revoked_at, s.user_id, u.email, u.role
       FROM user_session_refresh r
       JOIN user_session s ON s.session_id = r.session_id
       JOIN user_master u ON u.user_id = s.user_id
       WHERE r.refresh_token_hash = $1
       FOR UPDATE OF r`,
      [hash],
    );

    const row = found.rows[0];
    if (!row) {
      throw httpError(401, 'Your session has expired. Please log in again.', 'REFRESH_TOKEN_INVALID');
    }

    if (row.replaced_at) {
      await client.query(
        `UPDATE user_session
         SET revoked_at = NOW(), revocation_reason = 'refresh_reuse'
         WHERE token_family_id = $1
           AND revoked_at IS NULL`,
        [row.token_family_id],
      );
      await client.query('COMMIT');
      committed = true;
      throw httpError(401, 'Your session has expired. Please log in again.', 'REFRESH_TOKEN_REUSED');
    }

    if (row.revoked_at || new Date(row.expires_at).getTime() <= Date.now()) {
      throw httpError(401, 'Your session has expired. Please log in again.', 'SESSION_EXPIRED');
    }

    const refreshToken = newRefreshToken();
    const expiresAt = refreshExpiryDate();

    await client.query(
      `UPDATE user_session_refresh
       SET replaced_at = NOW()
       WHERE refresh_id = $1`,
      [row.refresh_id],
    );

    await client.query(
      `INSERT INTO user_session_refresh (session_id, token_family_id, refresh_token_hash, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [row.session_id, row.token_family_id, hashRefreshToken(refreshToken), expiresAt],
    );

    await client.query(
      `UPDATE user_session
       SET last_used_at = NOW(), expires_at = $2
       WHERE session_id = $1`,
      [row.session_id, expiresAt],
    );

    await client.query('COMMIT');
    committed = true;

    return {
      refreshToken,
      sessionId: row.session_id,
      userId: row.user_id,
      email: row.email,
      role: row.role,
    };
  } catch (error) {
    if (!committed) {
      await client.query('ROLLBACK');
    }
    throw error;
  } finally {
    client.release();
  }
}

export async function revokeByRefreshToken(rawToken) {
  const hash = hashRefreshToken(rawToken);
  await pool.query(
    `UPDATE user_session s
     SET revoked_at = NOW(), revocation_reason = 'logout'
     FROM user_session_refresh r
     WHERE r.refresh_token_hash = $1
       AND r.session_id = s.session_id
       AND s.revoked_at IS NULL`,
    [hash],
  );
}
