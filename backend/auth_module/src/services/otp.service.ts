/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/services/otp.service.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Commit: <commit-hash> | Initial OTP service — Redis-backed, 5-min TTL, crypto random generation
 *
 * Aim: OTP Generation & Validation Service
 * Why: Handles secure OTP generation (6-digit, cryptographically random)
 *      and validation strictly via Redis with a 5-minute TTL.
 *      Zero OTP storage in PostgreSQL — fully stateless in DB.
 *      Keys format: otp:<identifier> -> hashed OTP value.
 * ============================================================
 */

import crypto from 'crypto';
import redis from '../config/redis';

const OTP_TTL_SECONDS = 300; // 5 minutes
const OTP_LENGTH = 6;

/**
 * Generate a cryptographically secure 6-digit OTP.
 * Returns the raw OTP (to send via SMS/Email) and its SHA-256 hash.
 */
export const generateOtp = (): { rawOtp: string; hashedOtp: string } => {
  const rawOtp = crypto
    .randomInt(100000, 999999)
    .toString();

  const hashedOtp = crypto
    .createHash('sha256')
    .update(rawOtp)
    .digest('hex');

  return { rawOtp, hashedOtp };
};

/**
 * Store hashed OTP in Redis with 5-minute TTL.
 * Key format: otp:<identifier> (e.g., otp:parent@example.com, otp:childhandle)
 */
export const storeOtp = async (
  identifier: string,
  hashedOtp: string,
): Promise<void> => {
  const key = `otp:${identifier}`;
  await redis.setex(key, OTP_TTL_SECONDS, hashedOtp);
};

/**
 * Validate OTP against Redis-stored hash.
 * Returns true if OTP matches and is within TTL.
 * Deletes the OTP after successful validation (one-time use).
 */
export const validateOtp = async (
  identifier: string,
  rawOtp: string,
): Promise<boolean> => {
  const key = `otp:${identifier}`;
  const storedHash = await redis.get(key);

  if (!storedHash) {
    return false; // Expired or never sent
  }

  const inputHash = crypto
    .createHash('sha256')
    .update(rawOtp)
    .digest('hex');

  if (inputHash === storedHash) {
    await redis.del(key); // One-time use — delete after success
    return true;
  }

  return false;
};

/**
 * Check if an OTP already exists for this identifier (prevents spam).
 */
export const otpExists = async (identifier: string): Promise<boolean> => {
  const key = `otp:${identifier}`;
  const exists = await redis.exists(key);
  return exists === 1;
};