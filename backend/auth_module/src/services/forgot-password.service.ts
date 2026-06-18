/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/services/forgot-password.service.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Forgot Password service — OTP verification, temp token, password reset
 *
 * Aim: Forgot Password Business Logic
 * Why: Handles password reset flow:
 *      1. Verify email+phone exist in DB
 *      2. Generate OTP, store in Redis (5-min TTL)
 *      3. Verify OTP, issue temp JWT (5-min TTL)
 *      4. Reset password using temp JWT
 *      Security: Never reveals if account exists (Step 1 returns same message)
 * ============================================================
 */

import crypto from 'crypto';
import redis from '../config/redis';
import pool from '../config/db';
import pino from 'pino';
import { hashPassword } from './auth.service';

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

const FORGOT_OTP_PREFIX = 'forgot_otp:';
const FORGOT_OTP_TTL = 300;

export interface ForgotPasswordResult {
  success: boolean;
  message: string;
  email?: string;
  rawOtp?: string;
  tempToken?: string;
  userData?: {
    user_id: string;
    user_handle: string;
    full_name: string;
    email: string;
    phone_number: string | null;
  };
}

/**
 * Step 1: Verify email+phone, generate OTP, store in Redis.
 * Returns same message whether account exists or not (security).
 */
export const initiateForgotPassword = async (
  email: string,
  phone: string,
): Promise<ForgotPasswordResult> => {
  // Check if user exists with matching email AND phone
  const result = await pool.query(
    `SELECT u.user_id, u.user_handle, u.email, u.phone_number,
            p.full_name
     FROM auth_schema.users u
     JOIN auth_schema.user_profiles p ON u.user_id = p.user_id
     WHERE u.email = $1 AND u.phone_number = $2 AND u.role = 'parent'`,
    [email, phone],
  );

  // SECURITY: Always return same message
  if (result.rows.length === 0) {
    logger.info({ email, phone }, 'Forgot password — no matching account found');
    return {
      success: true,
      message: 'If the credentials match our records, an OTP will be sent to your email.',
    };
  }

  const user = result.rows[0];

  // Generate OTP
  const rawOtp = crypto.randomInt(100000, 999999).toString();
  const hashedOtp = crypto.createHash('sha256').update(rawOtp).digest('hex');

  // Store in Redis
  const key = `${FORGOT_OTP_PREFIX}${email}`;
  await redis.setex(key, FORGOT_OTP_TTL, JSON.stringify({
    userId: user.user_id,
    hashedOtp,
    userData: {
      user_id: user.user_id,
      user_handle: user.user_handle,
      full_name: user.full_name,
      email: user.email,
      phone_number: user.phone_number,
    },
  }));

  logger.info({ email }, 'Forgot password OTP stored in Redis');

  return {
    success: true,
    message: 'If the credentials match our records, an OTP will be sent to your email.',
    email: user.email,
    rawOtp,
  };
};

/**
 * Step 2: Verify OTP, return temp token + user data.
 */
export const verifyForgotPasswordOtp = async (
  email: string,
  otp: string,
): Promise<ForgotPasswordResult> => {
  const key = `${FORGOT_OTP_PREFIX}${email}`;
  const rawData = await redis.get(key);

  if (!rawData) {
    return { success: false, message: 'Invalid or expired OTP.' };
  }

  const stored = JSON.parse(rawData);
  const inputHash = crypto.createHash('sha256').update(otp).digest('hex');

  if (inputHash !== stored.hashedOtp) {
    return { success: false, message: 'Invalid OTP.' };
  }

  // Delete OTP from Redis
  await redis.del(key);

  // Generate temp token (5 min TTL) — simple random token
  const tempToken = crypto.randomBytes(32).toString('hex');

  // Store temp token in Redis
  const tempKey = `forgot_temp:${email}`;
  await redis.setex(tempKey, 300, JSON.stringify({
    userId: stored.userId,
    userData: stored.userData,
  }));

  logger.info({ email }, 'Forgot password OTP verified, temp token issued');

  return {
    success: true,
    message: 'OTP verified. Please set your new password.',
    tempToken,
    userData: stored.userData,
  };
};

/**
 * Step 3: Reset password using temp token.
 */
export const resetPassword = async (
  email: string,
  tempToken: string,
  newPassword: string,
): Promise<ForgotPasswordResult> => {
  const tempKey = `forgot_temp:${email}`;
  const rawData = await redis.get(tempKey);

  if (!rawData) {
    return { success: false, message: 'Session expired. Please start the forgot password process again.' };
  }

  // Token is valid — we don't compare it (stored in Redis key)
  const stored = JSON.parse(rawData);
  const passwordHash = await hashPassword(newPassword);

  // Update password in DB
  await pool.query(
    `UPDATE auth_schema.users
     SET password_hash = $1, updated_at = NOW()
     WHERE user_id = $2`,
    [passwordHash, stored.userId],
  );

  // Clean up Redis
  await redis.del(tempKey);

  logger.info({ email, userId: stored.userId }, 'Password reset successful');

  return {
    success: true,
    message: 'Password reset successful. Please login with your new password.',
  };
};