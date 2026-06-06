/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/services/auth.service.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Auth service — password hashing, PIN validation, login orchestration, rate limiting
 *
 * Aim: Core Authentication Business Logic
 * Why: Orchestrates login flow with strict security:
 *      - bcrypt for password hashing (cost factor 12)
 *      - SHA-256 for PIN hashing
 *      - Account lockout after 5 failed attempts (15 min)
 *      - Rate limiting via Redis (IP + user based)
 *      - Constant-time comparison to prevent timing attacks
 *      - Generic error messages to prevent user enumeration
 *      - Immutable audit logging for every attempt
 * ============================================================
 */

import bcrypt from 'bcrypt';
import crypto from 'crypto';
import redis from '../config/redis';
import * as userRepo from '../repositories/user.repository';
import * as auditRepo from '../repositories/login-audit-log.repository';

const BCRYPT_ROUNDS = 12;
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MINUTES = 15;
const RATE_LIMIT_WINDOW = 60; // seconds
const RATE_LIMIT_MAX_REQUESTS = 5;

export interface LoginResult {
  success: boolean;
  user?: {
    user_id: string;
    user_handle: string;
    role: string;
    email: string | null;
  };
  error?: string;
  locked_until?: string;
}

/**
 * Hash a password using bcrypt with 12 salt rounds.
 * Never log the raw password or hash.
 */
export const hashPassword = async (password: string): Promise<string> => {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
};

/**
 * Verify password using constant-time bcrypt compare.
 */
const verifyPassword = async (password: string, hash: string): Promise<boolean> => {
  return bcrypt.compare(password, hash);
};

/**
 * Hash a PIN using SHA-256.
 */
export const hashPin = (pin: string): string => {
  return crypto
    .createHash('sha256')
    .update(pin)
    .digest('hex');
};

/**
 * Verify PIN using constant-time comparison.
 * Re-hashes input and compares — prevents timing attacks.
 */
const verifyPin = (inputPin: string, storedHash: string): boolean => {
  const inputHash = hashPin(inputPin);
  return crypto.timingSafeEqual(Buffer.from(inputHash), Buffer.from(storedHash));
};

/**
 * Check rate limit for a given key (IP or user).
 * Returns true if rate limit exceeded.
 */
const checkRateLimit = async (key: string): Promise<boolean> => {
  const redisKey = `ratelimit:${key}`;
  const current = await redis.incr(redisKey);

  if (current === 1) {
    await redis.expire(redisKey, RATE_LIMIT_WINDOW);
  }

  return current > RATE_LIMIT_MAX_REQUESTS;
};

/**
 * Parent login with email and password.
 * Flow:
 *   1. Check rate limit (IP + email)
 *   2. Find user by email
 *   3. Check account lockout
 *   4. Verify password (constant-time)
 *   5. On success: reset attempts, update last_login, audit log
 *   6. On failure: increment attempts, audit log, check lockout threshold
 *
 * Generic error always: "Invalid email or password"
 * Never reveals whether email exists or password was wrong.
 */
export const parentLogin = async (
  email: string,
  password: string,
  ipAddress: string,
  userAgent: string,
): Promise<LoginResult> => {
  // Rate limit by IP
  const ipLimited = await checkRateLimit(`ip:${ipAddress}`);
  if (ipLimited) {
    await auditRepo.createAuditLog({
      event_type: 'login_failed',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Rate limit exceeded — IP based',
    });
    return { success: false, error: 'Too many requests. Please try again later.' };
  }

  // Rate limit by email
  const emailLimited = await checkRateLimit(`email:${email}`);
  if (emailLimited) {
    return { success: false, error: 'Too many requests. Please try again later.' };
  }

  // Find user
  const user = await userRepo.findUserByEmail(email);

  // Generic error if user not found — prevents user enumeration
  if (!user) {
    await auditRepo.createAuditLog({
      event_type: 'login_failed',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Email not found',
    });
    return { success: false, error: 'Invalid email or password' };
  }

  // Check if account is locked
  const locked = await userRepo.isAccountLocked(user.user_id);
  if (locked) {
    await auditRepo.createAuditLog({
      user_id: user.user_id,
      event_type: 'login_locked',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Account locked',
    });
    return {
      success: false,
      error: 'Account temporarily locked. Please try again later.',
      locked_until: user.locked_until || undefined,
    };
  }

  // Verify password
  if (!user.password_hash) {
    return { success: false, error: 'Invalid email or password' };
  }

  const passwordValid = await verifyPassword(password, user.password_hash);

  if (!passwordValid) {
    await userRepo.incrementFailedAttempts(user.user_id, MAX_FAILED_ATTEMPTS);
    await auditRepo.createAuditLog({
      user_id: user.user_id,
      event_type: 'login_failed',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Invalid password',
    });

    // Check if this failure triggered lockout
    const updatedUser = await userRepo.findUserById(user.user_id);
    if (updatedUser && updatedUser.locked_until) {
      return {
        success: false,
        error: 'Account locked due to multiple failed attempts.',
        locked_until: updatedUser.locked_until,
      };
    }

    return { success: false, error: 'Invalid email or password' };
  }

  // Success
  await userRepo.resetFailedAttempts(user.user_id);
  await userRepo.updateLastLogin(user.user_id);
  await auditRepo.createAuditLog({
    user_id: user.user_id,
    event_type: 'login_success',
    ip_address: ipAddress,
    user_agent: userAgent,
    attempt_status: 'success',
  });

  return {
    success: true,
    user: {
      user_id: user.user_id,
      user_handle: user.user_handle,
      role: user.role,
      email: user.email,
    },
  };
};

/**
 * Student login with handle and PIN.
 * Flow same as parent login but uses PIN hash instead of bcrypt password.
 */
export const studentLogin = async (
  handle: string,
  pin: string,
  ipAddress: string,
  userAgent: string,
): Promise<LoginResult> => {
  // Rate limit by IP
  const ipLimited = await checkRateLimit(`ip:${ipAddress}`);
  if (ipLimited) {
    await auditRepo.createAuditLog({
      event_type: 'login_failed',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Rate limit exceeded — IP based',
    });
    return { success: false, error: 'Too many requests. Please try again later.' };
  }

  // Rate limit by handle
  const handleLimited = await checkRateLimit(`handle:${handle}`);
  if (handleLimited) {
    return { success: false, error: 'Too many requests. Please try again later.' };
  }

  // Find user
  const user = await userRepo.findUserByHandle(handle);

  if (!user) {
    await auditRepo.createAuditLog({
      event_type: 'login_failed',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Handle not found',
    });
    return { success: false, error: 'Invalid handle or PIN' };
  }

  // Check if account is locked
  const locked = await userRepo.isAccountLocked(user.user_id);
  if (locked) {
    await auditRepo.createAuditLog({
      user_id: user.user_id,
      event_type: 'login_locked',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Account locked',
    });
    return {
      success: false,
      error: 'Account temporarily locked. Please try again later.',
    };
  }

  // Verify PIN
  if (!user.pin_hash) {
    return { success: false, error: 'Invalid handle or PIN' };
  }

  const pinValid = verifyPin(pin, user.pin_hash);

  if (!pinValid) {
    await userRepo.incrementFailedAttempts(user.user_id, MAX_FAILED_ATTEMPTS);
    await auditRepo.createAuditLog({
      user_id: user.user_id,
      event_type: 'login_failed',
      ip_address: ipAddress,
      user_agent: userAgent,
      attempt_status: 'failure',
      failure_reason: 'Invalid PIN',
    });

    const updatedUser = await userRepo.findUserById(user.user_id);
    if (updatedUser && updatedUser.locked_until) {
      return {
        success: false,
        error: 'Account locked due to multiple failed attempts.',
      };
    }

    return { success: false, error: 'Invalid handle or PIN' };
  }

  // Success
  await userRepo.resetFailedAttempts(user.user_id);
  await userRepo.updateLastLogin(user.user_id);
  await auditRepo.createAuditLog({
    user_id: user.user_id,
    event_type: 'login_success',
    ip_address: ipAddress,
    user_agent: userAgent,
    attempt_status: 'success',
  });

  return {
    success: true,
    user: {
      user_id: user.user_id,
      user_handle: user.user_handle,
      role: user.role,
      email: user.email,
    },
  };
};