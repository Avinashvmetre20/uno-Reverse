import { Pool } from 'pg';
import env from '../config/env.js';

const pool = new Pool({
  connectionString: env.databaseUrl,
  ssl: { rejectUnauthorized: true },
});

export default pool;
