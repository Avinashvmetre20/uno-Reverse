import {
  createBank,
  createCard,
  createTransaction,
  findActiveBankById,
  findActiveBanksByUserId,
  findActiveCardById,
  findActiveCardsByUserId,
  findActiveTransactionsByUserId,
  softDeleteBank,
  softDeleteCard,
  updateBank,
  updateCard,
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
    previousBalance: row.previous_balance,
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
    previousBalance: payload.previousBalance,
    balanceAmount: payload.balanceAmount,
    purpose: payload.purpose,
    notes: payload.notes,
    transactionDate: payload.transactionDate,
  });

  return mapTransaction(transaction);
}

export async function listUserTransactions(userId) {
  const transactions = await findActiveTransactionsByUserId(userId);
  return transactions.map(mapTransaction);
}
