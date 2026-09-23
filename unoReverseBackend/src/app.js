import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import healthRoutes from './modules/health/health.routes.js';
import authRoutes from './modules/auth/auth.routes.js';
import bankRoutes from './modules/bank/bank.routes.js';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  const start = Date.now();
  const originalJson = res.json.bind(res);
  let responseBody;

  res.json = (body) => {
    responseBody = body;
    return originalJson(body);
  };

  res.on('finish', () => {
    const ms = Date.now() - start;
    const endpoint = `${req.method} ${req.originalUrl}`;

    if (res.statusCode >= 400) {
      const errorMessage = responseBody?.message || 'Request failed';
      console.log(`${endpoint} ${ms}ms FAILED - ${errorMessage}`);
      return;
    }

    console.log(`${endpoint} ${ms}ms SUCCESS`);
  });

  next();
});

app.use('/health', healthRoutes);
app.use('/auth', authRoutes);
app.use(bankRoutes);

export default app;
