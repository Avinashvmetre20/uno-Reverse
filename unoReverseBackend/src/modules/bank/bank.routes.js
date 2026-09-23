import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate.js';
import {
  create,
  createCard,
  createTransaction,
  list,
  listCards,
  listTransactions,
  remove,
  removeCard,
  update,
  updateCard,
} from './bank.controller.js';

const router = Router();

router.post('/banks', authenticate, create);
router.get('/banks', authenticate, list);
router.put('/banks/:bankId', authenticate, update);
router.delete('/banks/:bankId', authenticate, remove);

router.post('/cards', authenticate, createCard);
router.get('/cards', authenticate, listCards);
router.put('/cards/:cardId', authenticate, updateCard);
router.delete('/cards/:cardId', authenticate, removeCard);

router.post('/transactions', authenticate, createTransaction);
router.get('/transactions', authenticate, listTransactions);

export default router;
