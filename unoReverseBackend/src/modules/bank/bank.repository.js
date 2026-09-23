import pool from '../../database/connection.js';

export async function createBank({
  userId,
  bankName,
  accountType,
  accountLast4,
  balance,
}) {
  const result = await pool.query(
    `INSERT INTO bank_master (
       user_id, bank_name, account_type, account_last_4, balance
     )
     VALUES ($1, $2, $3, $4, $5)
     RETURNING bank_id, user_id, bank_name, account_type, account_last_4,
               balance, is_active, created_at, updated_at`,
    [userId, bankName, accountType, accountLast4, balance],
  );

  return result.rows[0];
}

export async function findActiveBanksByUserId(userId) {
  const result = await pool.query(
    `SELECT bank_id, user_id, bank_name, account_type, account_last_4,
            balance, is_active, created_at, updated_at
     FROM bank_master
     WHERE user_id = $1 AND is_active = TRUE
     ORDER BY created_at DESC`,
    [userId],
  );

  return result.rows;
}

export async function findActiveBankById(bankId, userId) {
  const result = await pool.query(
    `SELECT bank_id, user_id, bank_name, account_type, account_last_4,
            balance, is_active, created_at, updated_at
     FROM bank_master
     WHERE bank_id = $1 AND user_id = $2 AND is_active = TRUE
     LIMIT 1`,
    [bankId, userId],
  );

  return result.rows[0] || null;
}

export async function updateBank(bankId, userId, fields) {
  const sets = [];
  const values = [bankId, userId];

  if (fields.bankName !== undefined) {
    values.push(fields.bankName);
    sets.push(`bank_name = $${values.length}`);
  }

  if (fields.accountType !== undefined) {
    values.push(fields.accountType);
    sets.push(`account_type = $${values.length}`);
  }

  if (fields.accountLast4 !== undefined) {
    values.push(fields.accountLast4);
    sets.push(`account_last_4 = $${values.length}`);
  }

  if (fields.balance !== undefined) {
    values.push(fields.balance);
    sets.push(`balance = $${values.length}`);
  }

  sets.push('updated_at = NOW()');

  const result = await pool.query(
    `UPDATE bank_master
     SET ${sets.join(', ')}
     WHERE bank_id = $1 AND user_id = $2 AND is_active = TRUE
     RETURNING bank_id, user_id, bank_name, account_type, account_last_4,
               balance, is_active, created_at, updated_at`,
    values,
  );

  return result.rows[0] || null;
}

export async function softDeleteBank(bankId, userId) {
  const result = await pool.query(
    `UPDATE bank_master
     SET is_active = FALSE,
         updated_at = NOW()
     WHERE bank_id = $1 AND user_id = $2 AND is_active = TRUE
     RETURNING bank_id`,
    [bankId, userId],
  );

  return result.rows[0] || null;
}

export async function createCard({
  userId,
  bankId,
  cardName,
  cardType,
  cardLast4,
}) {
  const result = await pool.query(
    `INSERT INTO card_master (
       user_id, bank_id, card_name, card_type, card_last_4
     )
     VALUES ($1, $2, $3, $4, $5)
     RETURNING card_id, user_id, bank_id, card_name, card_type, card_last_4,
               is_active, created_at, updated_at`,
    [userId, bankId, cardName, cardType, cardLast4],
  );

  return result.rows[0];
}

export async function findActiveCardsByUserId(userId) {
  const result = await pool.query(
    `SELECT card_id, user_id, bank_id, card_name, card_type, card_last_4,
            is_active, created_at, updated_at
     FROM card_master
     WHERE user_id = $1 AND is_active = TRUE
     ORDER BY created_at DESC`,
    [userId],
  );

  return result.rows;
}

export async function updateCard(cardId, userId, fields) {
  const sets = [];
  const values = [cardId, userId];

  if (fields.bankId !== undefined) {
    values.push(fields.bankId);
    sets.push(`bank_id = $${values.length}`);
  }

  if (fields.cardName !== undefined) {
    values.push(fields.cardName);
    sets.push(`card_name = $${values.length}`);
  }

  if (fields.cardType !== undefined) {
    values.push(fields.cardType);
    sets.push(`card_type = $${values.length}`);
  }

  if (fields.cardLast4 !== undefined) {
    values.push(fields.cardLast4);
    sets.push(`card_last_4 = $${values.length}`);
  }

  sets.push('updated_at = NOW()');

  const result = await pool.query(
    `UPDATE card_master
     SET ${sets.join(', ')}
     WHERE card_id = $1 AND user_id = $2 AND is_active = TRUE
     RETURNING card_id, user_id, bank_id, card_name, card_type, card_last_4,
               is_active, created_at, updated_at`,
    values,
  );

  return result.rows[0] || null;
}

export async function softDeleteCard(cardId, userId) {
  const result = await pool.query(
    `UPDATE card_master
     SET is_active = FALSE,
         updated_at = NOW()
     WHERE card_id = $1 AND user_id = $2 AND is_active = TRUE
     RETURNING card_id`,
    [cardId, userId],
  );

  return result.rows[0] || null;
}

export async function findActiveCardById(cardId, userId) {
  const result = await pool.query(
    `SELECT card_id, user_id, bank_id, card_name, card_type, card_last_4,
            is_active, created_at, updated_at
     FROM card_master
     WHERE card_id = $1 AND user_id = $2 AND is_active = TRUE
     LIMIT 1`,
    [cardId, userId],
  );

  return result.rows[0] || null;
}

export async function createTransaction({
  userId,
  bankId,
  cardId,
  transactionType,
  amount,
  previousBalance,
  balanceAmount,
  purpose,
  notes,
  transactionDate,
}) {
  const result = await pool.query(
    `INSERT INTO user_transaction (
       user_id, bank_id, card_id, transaction_type, amount,
       previous_balance, balance_amount, purpose, notes, transaction_date
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, COALESCE($10, NOW()))
     RETURNING user_transaction_id, user_id, bank_id, card_id, transaction_type,
               amount, previous_balance, balance_amount, purpose, notes,
               transaction_date, is_active, created_at, updated_at`,
    [
      userId,
      bankId,
      cardId,
      transactionType,
      amount,
      previousBalance,
      balanceAmount,
      purpose,
      notes,
      transactionDate,
    ],
  );

  return result.rows[0];
}

export async function findActiveTransactionsByUserId(userId) {
  const result = await pool.query(
    `SELECT user_transaction_id, user_id, bank_id, card_id, transaction_type,
            amount, previous_balance, balance_amount, purpose, notes,
            transaction_date, is_active, created_at, updated_at
     FROM user_transaction
     WHERE user_id = $1 AND is_active = TRUE
     ORDER BY transaction_date DESC, created_at DESC`,
    [userId],
  );

  return result.rows;
}
