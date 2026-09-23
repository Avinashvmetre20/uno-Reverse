import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import healthRoutes from './modules/health/health.routes.js';
import authRoutes from './modules/auth/auth.routes.js';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    console.log(`${req.method} ${req.originalUrl} ${Date.now() - start}ms`);
  });

  next();
});

app.use('/health', healthRoutes);
app.use('/auth', authRoutes);

export default app;
