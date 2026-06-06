/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/config/db.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Commit: d4572d1 | Initial PostgreSQL connection pool — Tailscale IP, koshiv_kla database
 *
 * Aim: PostgreSQL Connection Pool for Auth Module
 * Why: Creates a pg Pool connected to koshiv_kla database at
 *      100.81.13.80:34551 via Tailscale. All auth data (users,
 *      profiles, consents, device credentials) lives in this DB.
 *      Pool max 20, idle timeout 30s, connection timeout 5s.
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