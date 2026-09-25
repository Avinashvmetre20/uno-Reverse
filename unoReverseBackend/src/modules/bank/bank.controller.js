import {
  createBankAccount,
  createCardAccount,
  createUserTransaction,
  deleteBankAccount,
  deleteCardAccount,
  insertSpendGainUserTransaction,
  listBankAccounts,
  listBankBalances,
  listCreditCardBalances,
  listCardAccounts,
  listUserTransactions,
  updateBankAccount,
  updateCardAccount,
} from './bank.service.js';

function optionalText(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  return trimmed || null;
}

function optionalBankId(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }

  const bankId = Number(value);
  return Number.isInteger(bankId) && bankId > 0 ? bankId : null;
}

export async function create(req, res) {
  const bankName = typeof req.body?.bankName === 'string' ? req.body.bankName.trim() : '';
  const accountType = optionalText(req.body?.accountType);
  const accountLast4 = optionalText(req.body?.accountLast4);
  const balance =
    req.body?.balance === undefined || req.body?.balance === null || req.body?.balance === ''
      ? null
      : Number(req.body.balance);

  if (!bankName) {
    res.status(400).json({ message: 'bankName is required' });
    return;
  }

  try {
    const bank = await createBankAccount(req.user.userId, {
      bankName,
      accountType,
      accountLast4,
      balance: Number.isFinite(balance) ? balance : null,
    });

    res.status(201).json(bank);
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to create bank account' : error.message,
    });
  }
}

export async function list(req, res) {
  try {
    const banks = await listBankAccounts(req.user.userId);
    res.status(200).json(banks);
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to load bank accounts' : error.message,
    });
  }
}

export async function getBankBalance(req, res) {
  try {
    const data = await listBankBalances(req.user.userId);
    res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      success: false,
      message: status === 500 ? 'Unable to load bank balances' : error.message,
    });
  }
}

export async function getCreditCardBalance(req, res) {
  try {
    const data = await listCreditCardBalances(req.user.userId);
    res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      success: false,
      message: status === 500 ? 'Unable to load credit card balances' : error.message,
    });
  }
}

export async function update(req, res) {
  const bankId = Number(req.params.bankId);

  if (!Number.isInteger(bankId) || bankId <= 0) {
    res.status(400).json({ message: 'Valid bankId is required' });
    return;
  }

  const body = req.body || {};
  const payload = {};

  if (Object.prototype.hasOwnProperty.call(body, 'bankName')) {
    const bankName = typeof body.bankName === 'string' ? body.bankName.trim() : '';
    if (!bankName) {
      res.status(400).json({ message: 'bankName cannot be empty' });
      return;
    }
    payload.bankName = bankName;
  }

  if (Object.prototype.hasOwnProperty.call(body, 'accountType')) {
    payload.accountType = optionalText(body.accountType);
  }

  if (Object.prototype.hasOwnProperty.call(body, 'accountLast4')) {
    payload.accountLast4 = optionalText(body.accountLast4);
  }

  if (Object.prototype.hasOwnProperty.call(body, 'balance')) {
    if (body.balance === null || body.balance === '') {
      payload.balance = null;
    } else {
      const balance = Number(body.balance);
      payload.balance = Number.isFinite(balance) ? balance : null;
    }
  }

  if (Object.keys(payload).length === 0) {
    res.status(400).json({ message: 'At least one field is required to update' });
    return;
  }

  try {
    const bank = await updateBankAccount(req.user.userId, bankId, payload);
    res.status(200).json(bank);
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to update bank account' : error.message,
    });
  }
}

export async function remove(req, res) {
  const bankId = Number(req.params.bankId);

  if (!Number.isInteger(bankId) || bankId <= 0) {
    res.status(400).json({ message: 'Valid bankId is required' });
    return;
  }

  try {
    await deleteBankAccount(req.user.userId, bankId);
    res.status(200).json({ message: 'Bank account deleted' });
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to delete bank account' : error.message,
    });
  }
}

export async function createCard(req, res) {
  const cardName = typeof req.body?.cardName === 'string' ? req.body.cardName.trim() : '';
  const cardType = optionalText(req.body?.cardType);
  const cardLast4 = optionalText(req.body?.cardLast4);
  const hasBankId = Object.prototype.hasOwnProperty.call(req.body || {}, 'bankId');
  const bankId = hasBankId ? optionalBankId(req.body.bankId) : null;

  if (!cardName) {
    res.status(400).json({ message: 'cardName is required' });
    return;
  }

  if (hasBankId && req.body.bankId !== null && req.body.bankId !== '' && bankId === null) {
    res.status(400).json({ message: 'Valid bankId is required' });
    return;
  }

  try {
    const card = await createCardAccount(req.user.userId, {
      cardName,
      cardType,
      cardLast4,
      bankId,
    });

    res.status(201).json(card);
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to create card' : error.message,
    });
  }
}

export async function listCards(req, res) {
  try {
    const cards = await listCardAccounts(req.user.userId);
    res.status(200).json(cards);
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to load cards' : error.message,
    });
  }
}

export async function updateCard(req, res) {
  const cardId = Number(req.params.cardId);

  if (!Number.isInteger(cardId) || cardId <= 0) {
    res.status(400).json({ message: 'Valid cardId is required' });
    return;
  }

  const body = req.body || {};
  const payload = {};

  if (Object.prototype.hasOwnProperty.call(body, 'cardName')) {
    const cardName = typeof body.cardName === 'string' ? body.cardName.trim() : '';
    if (!cardName) {
      res.status(400).json({ message: 'cardName cannot be empty' });
      return;
    }
    payload.cardName = cardName;
  }

  if (Object.prototype.hasOwnProperty.call(body, 'cardType')) {
    payload.cardType = optionalText(body.cardType);
  }

  if (Object.prototype.hasOwnProperty.call(body, 'cardLast4')) {
    payload.cardLast4 = optionalText(body.cardLast4);
  }

  if (Object.prototype.hasOwnProperty.call(body, 'bankId')) {
    if (body.bankId === null || body.bankId === '') {
      payload.bankId = null;
    } else {
      const bankId = optionalBankId(body.bankId);
      if (bankId === null) {
        res.status(400).json({ message: 'Valid bankId is required' });
        return;
      }
      payload.bankId = bankId;
    }
  }

  if (Object.keys(payload).length === 0) {
    res.status(400).json({ message: 'At least one field is required to update' });
    return;
  }

  try {
    const card = await updateCardAccount(req.user.userId, cardId, payload);
    res.status(200).json(card);
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to update card' : error.message,
    });
  }
}

export async function removeCard(req, res) {
  const cardId = Number(req.params.cardId);

  if (!Number.isInteger(cardId) || cardId <= 0) {
    res.status(400).json({ message: 'Valid cardId is required' });
    return;
  }

  try {
    await deleteCardAccount(req.user.userId, cardId);
    res.status(200).json({ message: 'Card deleted' });
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to delete card' : error.message,
    });
  }
}

function optionalNumber(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export async function createTransaction(req, res) {
  const bankId = optionalBankId(req.body?.bankId);
  const hasCardId = Object.prototype.hasOwnProperty.call(req.body || {}, 'cardId');
  const cardId = hasCardId ? optionalBankId(req.body.cardId) : null;
  const transactionType =
    typeof req.body?.transactionType === 'string' ? req.body.transactionType.trim().toLowerCase() : '';
  const amount = optionalNumber(req.body?.amount);
  const balanceAmount = optionalNumber(req.body?.balanceAmount);
  const purpose = optionalText(req.body?.purpose);
  const notes = optionalText(req.body?.notes);
  const transactionDate =
    typeof req.body?.transactionDate === 'string' && req.body.transactionDate.trim()
      ? req.body.transactionDate.trim()
      : null;

  if (!bankId) {
    res.status(400).json({ message: 'bankId is required' });
    return;
  }

  if (!transactionType) {
    res.status(400).json({ message: 'transactionType is required' });
    return;
  }

  if (amount === null) {
    res.status(400).json({ message: 'amount is required' });
    return;
  }

  if (hasCardId && req.body.cardId !== null && req.body.cardId !== '' && cardId === null) {
    res.status(400).json({ message: 'Valid cardId is required' });
    return;
  }

  try {
    const transaction = await createUserTransaction(req.user.userId, {
      bankId,
      cardId,
      transactionType,
      amount,
      balanceAmount,
      purpose,
      notes,
      transactionDate,
    });

    res.status(201).json(transaction);
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      message: status === 500 ? 'Unable to create transaction' : error.message,
    });
  }
}

export async function listTransactions(req, res) {
  try {
    const transactions = await listUserTransactions(req.user.userId);
    res.status(200).json({
      success: true,
      data: transactions,
    });
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      success: false,
      message: status === 500 ? 'Unable to load transactions' : error.message,
    });
  }
}

export async function insertTransactions(req, res) {
  const bankId = optionalBankId(req.body?.bankId);
  const hasCardId = Object.prototype.hasOwnProperty.call(req.body || {}, 'cardId');
  const cardId = hasCardId ? optionalBankId(req.body.cardId) : null;
  const transactionType =
    typeof req.body?.transactionType === 'string'
      ? req.body.transactionType.trim().toLowerCase()
      : '';
  const amount = optionalNumber(req.body?.amount);
  const purpose = optionalText(req.body?.purpose);
  const notes = optionalText(req.body?.notes);

  try {
    const transaction = await insertSpendGainUserTransaction(req.user.userId, {
      bankId,
      cardId,
      transactionType,
      amount,
      purpose,
      notes,
    });

    res.status(201).json({
      success: true,
      data: transaction,
    });
  } catch (error) {
    const status = error.status || 500;
    res.status(status).json({
      success: false,
      message: status === 500 ? 'Unable to insert transaction' : error.message,
    });
  }
}
