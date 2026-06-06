/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/config/redis.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Commit: <commit-hash> | Initial Redis client — Tailscale 100.81.13.80:34553, ioredis
 *
 * Aim: Redis Client for Auth Module
 * Why: Connects to Redis 7 at 100.81.13.80:34553 via Tailscale.
 *      Used exclusively for OTP TTL caching and session management.
 *      Retry strategy: max 10 attempts, exponential backoff.
 * ============================================================
 */

import Redis from 'ioredis';
import dotenv from 'dotenv';

dotenv.config();

const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT || '34553', 10),
  password: process.env.REDIS_PASSWORD,
  db: parseInt(process.env.REDIS_DB || '0', 10),
  retryStrategy: (times: number) => {
    if (times > 10) {
      return null;
    }
    return Math.min(times * 200, 2000);
  },
});

redis.on('connect', () => {
  console.log('[Redis] Connected successfully.');
});

redis.on('error', (err: Error) => {
  console.error('[Redis] Error:', err.message);
});

export const connectRedis = async (): Promise<boolean> => {
  try {
    const pong = await redis.ping();
    return pong === 'PONG';
  } catch (error) {
    console.error('[Redis] Ping failed:', (error as Error).message);
    return false;
  }
};

export default redis;