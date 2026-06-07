/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/services/redis-hold.service.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Redis-Hold service — stores pending registration payload with hashed OTP, 5-min TTL
 *
 * Aim: Redis-Hold Pattern for Registration
 * Why: Temporarily stores full registration payload in Redis until
 *      email ownership is verified via OTP. Zero PostgreSQL interaction
 *      until OTP is validated. Prevents spam/orphan accounts.
 *      Key format: reg_pending:<email> → JSON payload
 *      TTL: 300 seconds (5 minutes)
 * ============================================================
 */

import crypto from 'crypto';
import redis from '../config/redis';
import pino from 'pino';
import { ParentRegistrationInput } from './registration.service';

const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:yyyy-mm-dd HH:MM:ss',
      ignore: 'pid,hostname',
    },
  },
  level: process.env.LOG_LEVEL || 'debug',
});

const REG_PENDING_PREFIX = 'reg_pending:';
const REG_TTL_SECONDS = 300;

export interface PendingRegistration {
  payload: ParentRegistrationInput;
  hashedOtp: string;
  createdAt: string;
}

/**
 * Generate OTP, hash it, store full payload in Redis, return raw OTP for email.
 * Key: reg_pending:<email>
 * TTL: 300 seconds
 */
export const initiateRegistration = async (
  input: ParentRegistrationInput,
): Promise<{ rawOtp: string } | { error: string }> => {
  const key = `${REG_PENDING_PREFIX}${input.email}`;

  // Check if already pending
  const existing = await redis.exists(key);
  if (existing) {
    logger.warn({ email: input.email }, 'Registration already pending');
    return { error: 'A registration is already in progress for this email. Please wait or check your inbox.' };
  }

  // Generate OTP
  const rawOtp = crypto.randomInt(100000, 999999).toString();
  const hashedOtp = crypto.createHash('sha256').update(rawOtp).digest('hex');

  const pendingData: PendingRegistration = {
    payload: input,
    hashedOtp,
    createdAt: new Date().toISOString(),
  };

  // Store in Redis
  await redis.setex(key, REG_TTL_SECONDS, JSON.stringify(pendingData));

  logger.info({ email: input.email }, 'Registration payload stored in Redis with 5-min TTL');
  return { rawOtp };
};

/**
 * Validate OTP and return stored payload.
 * If valid, deletes the Redis key and returns the payload.
 * If invalid or expired, returns null.
 */
export const completeRegistration = async (
  email: string,
  rawOtp: string,
): Promise<ParentRegistrationInput | null> => {
  const key = `${REG_PENDING_PREFIX}${email}`;
  const rawData = await redis.get(key);

  if (!rawData) {
    logger.warn({ email }, 'No pending registration found — expired or never initiated');
    return null;
  }

  const pending: PendingRegistration = JSON.parse(rawData);

  const inputHash = crypto.createHash('sha256').update(rawOtp).digest('hex');

  if (inputHash !== pending.hashedOtp) {
    logger.warn({ email }, 'OTP mismatch for pending registration');
    return null;
  }

  // Valid — delete key and return payload
  await redis.del(key);
  logger.info({ email }, 'OTP verified, registration payload retrieved from Redis');

  return pending.payload;
};