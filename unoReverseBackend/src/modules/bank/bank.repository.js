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

export async function findBankBalancesByUserId(userId) {
  const result = await pool.query(
    `SELECT um.user_id,
            bm.bank_id,
            bm.bank_name,
            bm.account_type,
            bm.account_last_4,
            bm.balance,
            COALESCE(
              json_agg(
                json_build_object(
                  'cardId', cm.card_id,
                  'cardName', cm.card_name,
                  'cardLast4', cm.card_last_4,
                  'creditLimit', cm.credit_limit,
                  'spentAmount', cm.spent_amount
                )
                ORDER BY cm.card_name ASC
              ) FILTER (WHERE cm.card_id IS NOT NULL),
              '[]'::json
            ) AS debit_cards
     FROM user_master um
     LEFT JOIN bank_master bm
       ON um.user_id = bm.user_id AND bm.is_active = TRUE
     LEFT JOIN card_master cm
       ON cm.bank_id = bm.bank_id
      AND cm.user_id = um.user_id
      AND cm.is_active = TRUE
      AND cm.card_type = 'Debit Card'
     WHERE um.user_id = $1 AND um.is_active = TRUE
     GROUP BY um.user_id, bm.bank_id, bm.bank_name, bm.account_type,
              bm.account_last_4, bm.balance
     ORDER BY bm.bank_name ASC NULLS LAST`,
    [userId],
  );

  return result.rows;
}

export async function findCreditCardBalancesByUserId(userId) {
  const result = await pool.query(
    `SELECT cm.card_id,
            cm.user_id,
            cm.bank_id,
            cm.card_name,
            cm.card_last_4,
            cm.credit_limit,
            cm.spent_amount
     FROM card_master cm
     WHERE cm.user_id = $1
       AND cm.is_active = TRUE
       AND cm.card_type = 'Credit Card'
     ORDER BY cm.card_name ASC`,
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
            credit_limit, spent_amount, is_active, created_at, updated_at
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
  balanceAmount,
  purpose,
  notes,
  transactionDate,
}) {
  const result = await pool.query(
    `INSERT INTO user_transaction (
       user_id, bank_id, card_id, transaction_type, amount,
       balance_amount, purpose, notes, transaction_date
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, COALESCE($9, NOW()))
     RETURNING user_transaction_id, user_id, bank_id, card_id, transaction_type,
               amount, balance_amount, purpose, notes,
               transaction_date, is_active, created_at, updated_at`,
    [
      userId,
      bankId,
      cardId,
      transactionType,
      amount,
      balanceAmount,
      purpose,
      notes,
      transactionDate,
    ],
  );

  return result.rows[0];
}

export async function insertSpendGainTransaction({
  userId,
  bankId,
  cardId,
  transactionType,
  amount,
  balanceAmount,
  purpose,
  notes,
  nextBankBalance,
  nextCreditLimit,
  nextSpentAmount,
  shouldUpdateBank,
  shouldUpdateCard,
  syncBankDebitCards = false,
}) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    if (shouldUpdateBank) {
      const bankResult = await client.query(
        `UPDATE bank_master
         SET balance = $3,
             updated_at = NOW()
         WHERE bank_id = $1 AND user_id = $2 AND is_active = TRUE
         RETURNING bank_id`,
        [bankId, userId, nextBankBalance],
      );

      if (!bankResult.rows[0]) {
        const error = new Error('Bank account not found');
        error.status = 404;
        throw error;
      }
    }

    if (syncBankDebitCards && nextCreditLimit !== undefined) {
      await client.query(
        `UPDATE card_master cm
         SET credit_limit = $3,
             updated_at = NOW()
         FROM bank_master bm
         WHERE cm.bank_id = bm.bank_id
           AND cm.user_id = bm.user_id
           AND bm.bank_id = $1
           AND bm.user_id = $2
           AND bm.is_active = TRUE
           AND cm.is_active = TRUE
           AND cm.card_type = 'Debit Card'`,
        [bankId, userId, nextCreditLimit],
      );
    } else if (shouldUpdateCard && cardId) {
      const sets = ['updated_at = NOW()'];
      const values = [cardId, userId];

      if (nextCreditLimit !== undefined) {
        values.push(nextCreditLimit);
        sets.push(`credit_limit = $${values.length}`);
      }

      if (nextSpentAmount !== undefined) {
        values.push(nextSpentAmount);
        sets.push(`spent_amount = $${values.length}`);
      }

      const cardResult = await client.query(
        `UPDATE card_master
         SET ${sets.join(', ')}
         WHERE card_id = $1 AND user_id = $2 AND is_active = TRUE
         RETURNING card_id`,
        values,
      );

      if (!cardResult.rows[0]) {
        const error = new Error('Card not found');
        error.status = 404;
        throw error;
      }
    }

    const txResult = await client.query(
      `INSERT INTO user_transaction (
         user_id, bank_id, card_id, transaction_type, amount,
         balance_amount, purpose, notes, transaction_date
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
       RETURNING user_transaction_id, user_id, bank_id, card_id, transaction_type,
                 amount, balance_amount, purpose, notes,
                 transaction_date, is_active, created_at, updated_at`,
      [
        userId,
        bankId,
        cardId,
        transactionType,
        amount,
        balanceAmount,
        purpose,
        notes,
      ],
    );

    await client.query('COMMIT');
    return txResult.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function findActiveTransactionsByUserId(userId) {
  const result = await pool.query(
    `SELECT user_transaction_id, user_id, bank_id, card_id, transaction_type,
            amount, balance_amount, purpose, notes,
            transaction_date, is_active, created_at, updated_at
     FROM user_transaction
     WHERE user_id = $1 AND is_active = TRUE
     ORDER BY transaction_date DESC, created_at DESC`,
    [userId],
  );

  return result.rows;
}
