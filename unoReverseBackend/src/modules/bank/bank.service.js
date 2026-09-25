import {
  createBank,
  createCard,
  createTransaction,
  findActiveBankById,
  findActiveBanksByUserId,
  findBankBalancesByUserId,
  findCreditCardBalancesByUserId,
  findActiveCardById,
  findActiveCardsByUserId,
  findActiveTransactionsByUserId,
  softDeleteBank,
  softDeleteCard,
  updateBank,
  updateCard,
  insertSpendGainTransaction,
} from './bank.repository.js';

function mapBank(row) {
  return {
    bankId: row.bank_id,
    userId: row.user_id,
    bankName: row.bank_name,
    accountType: row.account_type,
    accountLast4: row.account_last_4,
    balance: row.balance,
    isActive: row.is_active,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapCard(row) {
  return {
    cardId: row.card_id,
    userId: row.user_id,
    bankId: row.bank_id,
    cardName: row.card_name,
    cardType: row.card_type,
    cardLast4: row.card_last_4,
    isActive: row.is_active,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function ensureBankBelongsToUser(userId, bankId) {
  if (bankId === null) {
    return;
  }

  const bank = await findActiveBankById(bankId, userId);

  if (!bank) {
    const error = new Error('Bank account not found');
    error.status = 404;
    throw error;
  }
}

export async function createBankAccount(userId, payload) {
  const bank = await createBank({
    userId,
    bankName: payload.bankName,
    accountType: payload.accountType,
    accountLast4: payload.accountLast4,
    balance: payload.balance,
  });

  return mapBank(bank);
}

export async function listBankAccounts(userId) {
  const banks = await findActiveBanksByUserId(userId);
  return banks.map(mapBank);
}

export async function listBankBalances(userId) {
  const rows = await findBankBalancesByUserId(userId);

  return rows
    .filter((row) => row.bank_id != null)
    .map((row) => ({
      userId: row.user_id,
      bankId: row.bank_id,
      bankName: row.bank_name,
      accountType: row.account_type,
      accountLast4: row.account_last_4,
      balance: row.balance,
      debitCards: Array.isArray(row.debit_cards) ? row.debit_cards : [],
    }));
}

export async function listCreditCardBalances(userId) {
  const rows = await findCreditCardBalancesByUserId(userId);

  return rows.map((row) => ({
    cardId: row.card_id,
    userId: row.user_id,
    bankId: row.bank_id,
    cardName: row.card_name,
    cardLast4: row.card_last_4,
    creditLimit: row.credit_limit,
    spentAmount: row.spent_amount,
  }));
}

export async function updateBankAccount(userId, bankId, payload) {
  const bank = await updateBank(bankId, userId, payload);

  if (!bank) {
    const error = new Error('Bank account not found');
    error.status = 404;
    throw error;
  }

  return mapBank(bank);
}

export async function deleteBankAccount(userId, bankId) {
  const deleted = await softDeleteBank(bankId, userId);

  if (!deleted) {
    const error = new Error('Bank account not found');
    error.status = 404;
    throw error;
  }
}

export async function createCardAccount(userId, payload) {
  await ensureBankBelongsToUser(userId, payload.bankId);

  const card = await createCard({
    userId,
    bankId: payload.bankId,
    cardName: payload.cardName,
    cardType: payload.cardType,
    cardLast4: payload.cardLast4,
  });

  return mapCard(card);
}

export async function listCardAccounts(userId) {
  const cards = await findActiveCardsByUserId(userId);
  return cards.map(mapCard);
}

export async function updateCardAccount(userId, cardId, payload) {
  if (payload.bankId !== undefined) {
    await ensureBankBelongsToUser(userId, payload.bankId);
  }

  const card = await updateCard(cardId, userId, payload);

  if (!card) {
    const error = new Error('Card not found');
    error.status = 404;
    throw error;
  }

  return mapCard(card);
}

export async function deleteCardAccount(userId, cardId) {
  const deleted = await softDeleteCard(cardId, userId);

  if (!deleted) {
    const error = new Error('Card not found');
    error.status = 404;
    throw error;
  }
}

function mapTransaction(row) {
  return {
    userTransactionId: row.user_transaction_id,
    userId: row.user_id,
    bankId: row.bank_id,
    cardId: row.card_id,
    transactionType: row.transaction_type,
    amount: row.amount,
    balanceAmount: row.balance_amount,
    purpose: row.purpose,
    notes: row.notes,
    transactionDate: row.transaction_date,
    isActive: row.is_active,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function ensureCardBelongsToUser(userId, cardId) {
  if (cardId === null) {
    return;
  }

  const card = await findActiveCardById(cardId, userId);

  if (!card) {
    const error = new Error('Card not found');
    error.status = 404;
    throw error;
  }
}

export async function createUserTransaction(userId, payload) {
  await ensureBankBelongsToUser(userId, payload.bankId);
  await ensureCardBelongsToUser(userId, payload.cardId);

  const transaction = await createTransaction({
    userId,
    bankId: payload.bankId,
    cardId: payload.cardId,
    transactionType: payload.transactionType,
    amount: payload.amount,
    balanceAmount: payload.balanceAmount,
    purpose: payload.purpose,
    notes: payload.notes,
    transactionDate: payload.transactionDate,
  });

  return mapTransaction(transaction);
}

function toAmount(value) {
  const amount = Number(value);
  return Number.isFinite(amount) ? amount : 0;
}

function cardKind(cardType) {
  const type = String(cardType || '').trim();
  if (type === 'Credit Card') {
    return 'credit';
  }
  if (type === 'Debit Card') {
    return 'debit';
  }
  return 'other';
}

export async function insertSpendGainUserTransaction(userId, payload) {
  const amount = toAmount(payload.amount);
  const type = String(payload.transactionType || '').toLowerCase();

  const hasCard =
    payload.cardId !== null && payload.cardId !== undefined;
  const card = hasCard ? await findActiveCardById(payload.cardId, userId) : null;

  if (hasCard && !card) {
    const error = new Error('Card not found');
    error.status = 404;
    throw error;
  }

  const kind = card ? cardKind(card.card_type) : 'none';
  const bankId = payload.bankId ?? card?.bank_id ?? null;
  const bank = bankId == null ? null : await findActiveBankById(bankId, userId);

  if (bankId != null && !bank) {
    const error = new Error('Bank account not found');
    error.status = 404;
    throw error;
  }

  if (bankId == null && kind !== 'credit') {
    const error = new Error('bankId is required');
    error.status = 400;
    throw error;
  }

  const currentBankBalance = toAmount(bank?.balance);
  const currentSpent = card ? toAmount(card.spent_amount) : 0;

  let nextBankBalance = currentBankBalance;
  let nextCreditLimit;
  let nextSpentAmount;
  let balanceAmount;
  let shouldUpdateBank = false;
  let shouldUpdateCard = false;

  if (type === 'spend') {
    if (kind === 'credit') {
      nextSpentAmount = currentSpent + amount;
      balanceAmount = nextSpentAmount;
      shouldUpdateCard = true;
    } else {
      nextBankBalance = currentBankBalance - amount;
      balanceAmount = nextBankBalance;
      shouldUpdateBank = true;

      if (kind === 'debit') {
        nextCreditLimit = nextBankBalance;
        shouldUpdateCard = true;
      }
    }
  } else if (kind === 'credit') {
    nextSpentAmount = Math.max(0, currentSpent - amount);
    balanceAmount = nextSpentAmount;
    shouldUpdateCard = true;
  } else {
    // Gain with no card OR debit card: update bank + credit_limit
    nextBankBalance = currentBankBalance + amount;
    balanceAmount = nextBankBalance;
    shouldUpdateBank = true;
    nextCreditLimit = nextBankBalance;
    shouldUpdateCard = true;
  }

  const transaction = await insertSpendGainTransaction({
    userId,
    bankId,
    cardId: payload.cardId,
    transactionType: type,
    amount,
    balanceAmount,
    purpose: payload.purpose,
    notes: payload.notes,
    nextBankBalance,
    nextCreditLimit,
    nextSpentAmount,
    shouldUpdateBank,
    shouldUpdateCard,
    syncBankDebitCards: type === 'gain' && kind === 'none',
  });

  return mapTransaction(transaction);
}

export async function listUserTransactions(userId) {
  const transactions = await findActiveTransactionsByUserId(userId);
  return transactions.map((row) => {
    const transaction = mapTransaction(row);
    return {
      userTransactionId: transaction.userTransactionId,
      userId: transaction.userId,
      bankId: transaction.bankId,
      bankName: row.bank_name ?? null,
      cardId: transaction.cardId,
      cardName: row.card_name ?? null,
      transactionType: transaction.transactionType,
      amount: transaction.amount,
      balanceAmount: transaction.balanceAmount,
      purpose: transaction.purpose,
      notes: transaction.notes,
      transactionDate: transaction.transactionDate,
      isActive: transaction.isActive,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    };
  });
}
