import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate.js';
import { login, logout, profile, refresh, register } from './auth.controller.js';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refresh);
router.post('/logout', logout);
router.get('/profile', authenticate, profile);

export default router;
