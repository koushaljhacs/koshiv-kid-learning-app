/**
 * ============================================================
 * Project:      koshiv - Sovereign Edu Platform (Learning App for Kids)
 * File:         src/config/db.ts
 * Module:       auth_module
 * Version:      1.0.0
 * Author:       Backend Developer (Koushal Jha)
 * Date:         2026-06-06
 * Aim:          PostgreSQL connection pool for auth_module.
 *               Connects to koshiv_kla database via Tailscale.
 * Changelog:
 *   v1.0.0 (2026-06-06): Initial creation.
 * ============================================================
 */

import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '34551', 10),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('[DB Pool] Unexpected error:', err.message);
});

export const connectDb = async (): Promise<boolean> => {
  try {
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    return true;
  } catch (error) {
    console.error('[DB] Connection failed:', (error as Error).message);
    return false;
  }
};

export default pool;