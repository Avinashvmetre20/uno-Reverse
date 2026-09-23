import { Router } from 'express';
import { authenticate } from '../../middleware/authenticate.js';
import { login, profile, register } from './auth.controller.js';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/profile', authenticate, profile);

export default router;
