/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/controllers/auth.controller.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Auth controller — parent registration with FIDO2, child login with handle+PIN
 * Version 1.1.0 | Integrated auth.service.ts — real DB login for parent and student, rate limiting, audit logging
 * Version 1.2.0 | Added registerParent handler — transactional parent+child registration with handle generation
 * Version 1.2.1 | Fix: Updated FIDO2 import to verifyAndStoreCredential, removed deprecated verifyFido2RegistrationResponse
 * Version 1.3.0 | ARCH-01 Fix: Split registration into registerInit (Redis-Hold + OTP email) and registerComplete (OTP verify + DB transaction)
 * Version 1.3.1 | FEAT: Added credentials email dispatch after successful registration
 * Version 1.3.2 | PERF FIX: registerInit responds immediately after Redis store, sends email asynchronously
 * Version 1.3.3 | UX FIX: registerInit sends email synchronously with email_dispatched flag in response
 * Version 1.3.4 | UX FIX: On email failure, Redis pending key DELETED so user can retry immediately without lockout
 * Version 1.3.5 | VALIDATION FIX: Added email format regex validation BEFORE Redis store — invalid emails (e.g. "koushal2203") rejected with 400, zero Redis/SMTP waste
 *
 * Aim: Authentication HTTP Request/Response Handler
 * Why: Handles parent login, student login, 2-step parent+child registration.
 *      Validates email format BEFORE any Redis or SMTP operation.
 *      registerInit sends email synchronously, returns email_dispatched flag.
 *      On email failure, cleans up Redis so user can retry immediately.
 *      Delegates business logic to services. Never exposes internal errors.
 * ============================================================
 */

import { Request, Response } from 'express';
import pino from 'pino';
import redis from '../config/redis';
import { generateTokenPair, TokenPayload } from '../services/jwt.service';
import { parentLogin, studentLogin } from '../services/auth.service';
import { registerParentWithChild } from '../services/registration.service';
import { initiateRegistration, completeRegistration } from '../services/redis-hold.service';
import { sendOtpEmail } from '../config/mailer';
import { sendCredentialsEmail } from '../config/mailer';
import { generateFido2RegistrationOptions, verifyAndStoreCredential } from '../services/fido2.service';

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

/**
 * RFC 5322 compliant email regex.
 * Validates standard email format before any processing.
 */
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

/**
 * Validate email format.
 * Returns true if valid, false otherwise.
 */
const isValidEmail = (email: string): boolean => {
  return EMAIL_REGEX.test(email);
};

/**
 * Get client IP from request headers or connection.
 */
const getClientIp = (req: Request): string => {
  return (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ||
         req.ip ||
         'unknown';
};

/**
 * Get user agent from request.
 */
const getUserAgent = (req: Request): string => {
  return req.get('User-Agent') || 'unknown';
};

/**
 * POST /api/v1/auth/register/init
 * Body: { parent_name, email, password, phone_number?, child_name, child_dob?, child_grade? }
 *
 * Step 1 of 2: Redis-Hold Pattern.
 * VALIDATION ORDER:
 *   1. Required fields check
 *   2. EMAIL FORMAT validation (NEW v1.3.5) — reject BEFORE Redis/SMTP
 *   3. Check DB + Redis (initiateRegistration)
 *   4. Store payload+hashedOTP in Redis
 *   5. Send OTP email synchronously
 *   6. If email SUCCESS → respond email_dispatched:true
 *   7. If email FAIL → DELETE Redis key → respond email_dispatched:false
 */
export const registerInit = async (req: Request, res: Response): Promise<void> => {
  const { parent_name, email, password, phone_number, child_name, child_dob, child_grade } = req.body;

  // Step 1: Required fields
  if (!parent_name || !email || !password || !child_name) {
    logger.warn('Registration init request missing required fields');
    res.status(400).json({
      error: 'parent_name, email, password, and child_name are required',
    });
    return;
  }

  // Step 2: Email format validation (NEW — before Redis/SMTP)
  if (!isValidEmail(email)) {
    logger.warn({ email }, 'Registration init rejected — invalid email format');
    res.status(400).json({
      error: 'Invalid email format',
    });
    return;
  }

  try {
    // Step 3: Check DB + Redis
    const result = await initiateRegistration({
      parent_name,
      email,
      password,
      phone_number,
      child_name,
      child_dob,
      child_grade,
    });

    if ('error' in result) {
      res.status(409).json({ error: result.error });
      return;
    }

    // Step 4: Send email synchronously
    const emailSent = await sendOtpEmail(email, result.rawOtp);

    if (emailSent) {
      logger.info({ email }, 'Registration OTP email dispatched successfully');
      res.status(200).json({
        message: 'OTP sent to your email. Please verify to complete registration.',
        email_dispatched: true,
      });
    } else {
      // Step 5: Email failed — clean up Redis so user can retry immediately
      const redisKey = `reg_pending:${email}`;
      await redis.del(redisKey);
      logger.warn({ email, redisKey }, 'Email dispatch failed — Redis pending key deleted, user can retry');

      res.status(200).json({
        message: 'Failed to send OTP. Please try again.',
        email_dispatched: false,
      });
    }
  } catch (error) {
    logger.error({ err: error }, 'Registration init failed');
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
};

/**
 * POST /api/v1/auth/register/complete
 * Body: { email: string, otp: string }
 *
 * Step 2 of 2: Redis-Hold Pattern.
 * Validates OTP against Redis → retrieves stored payload →
 * executes BEGIN...COMMIT transaction in PostgreSQL →
 * deletes Redis key → sends child credentials via email →
 * returns handles + child PIN.
 */
export const registerComplete = async (req: Request, res: Response): Promise<void> => {
  const { email, otp } = req.body;

  if (!email || !otp || typeof email !== 'string' || typeof otp !== 'string') {
    logger.warn('Registration complete request missing fields');
    res.status(400).json({ error: 'Email and OTP are required' });
    return;
  }

  try {
    const payload = await completeRegistration(email, otp);

    if (!payload) {
      logger.warn({ email }, 'OTP validation failed or registration expired');
      res.status(401).json({ error: 'Invalid or expired OTP. Please start registration again.' });
      return;
    }

    const result = await registerParentWithChild(payload);

    if (!result.success) {
      res.status(500).json({ error: result.error });
      return;
    }

    logger.info({ email }, 'Registration completed successfully');

    sendCredentialsEmail(email, {
      parent_name: payload.parent_name,
      parent_handle: result.parent_handle!,
      child_name: payload.child_name,
      child_handle: result.child_handle!,
      child_pin: result.child_pin!,
    })
      .then((sent) => {
        if (sent) {
          logger.info({ email }, 'Child credentials email dispatched');
        } else {
          logger.error({ email }, 'Failed to send credentials email');
        }
      })
      .catch((emailError) => {
        logger.error({ err: emailError, email }, 'Credentials email dispatch failed');
      });

    res.status(201).json({
      message: 'Registration successful',
      parent_handle: result.parent_handle,
      child_handle: result.child_handle,
      child_pin: result.child_pin,
      parent_user_id: result.parent_user_id,
      child_user_id: result.child_user_id,
    });
  } catch (error) {
    logger.error({ err: error }, 'Registration complete failed');
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
};

/**
 * POST /api/v1/auth/parent/login
 * Body: { email: string, password: string }
 * Authenticates parent with email and password.
 * Rate limited, account lockout after 5 failures.
 */
export const parentLoginHandler = async (req: Request, res: Response): Promise<void> => {
  const { email, password } = req.body;

  if (!email || !password || typeof email !== 'string' || typeof password !== 'string') {
    logger.warn('Parent login request missing fields');
    res.status(400).json({ error: 'Email and password are required' });
    return;
  }

  try {
    const ipAddress = getClientIp(req);
    const userAgent = getUserAgent(req);

    const result = await parentLogin(email, password, ipAddress, userAgent);

    if (!result.success) {
      res.status(401).json({ error: result.error });
      return;
    }

    if (!result.user) {
      res.status(500).json({ error: 'An unexpected error occurred' });
      return;
    }

    const payload: TokenPayload = {
      sub: result.user.user_id,
      role: 'parent',
      email: result.user.email || undefined,
    };

    const tokens = generateTokenPair(payload);

    logger.info({ userId: result.user.user_id }, 'Parent logged in successfully');
    res.status(200).json({
      message: 'Login successful',
      user: {
        user_id: result.user.user_id,
        user_handle: result.user.user_handle,
        role: result.user.role,
      },
      ...tokens,
    });
  } catch (error) {
    logger.error({ err: error }, 'Parent login failed unexpectedly');
    res.status(500).json({ error: 'An unexpected error occurred' });
  }
};

/**
 * POST /api/v1/auth/parent/register/options
 * Body: { email: string }
 * Returns WebAuthn registration options for the browser.
 */
export const getRegistrationOptions = async (req: Request, res: Response): Promise<void> => {
  const { email } = req.body;

  if (!email || typeof email !== 'string') {
    logger.warn('Registration options request missing email');
    res.status(400).json({ error: 'Email is required' });
    return;
  }

  try {
    const userId = `parent_${Date.now()}`;
    const options = await generateFido2RegistrationOptions(userId, email);

    logger.info({ email }, 'FIDO2 registration options generated');
    res.status(200).json(options);
  } catch (error) {
    logger.error({ err: error }, 'Failed to generate registration options');
    res.status(500).json({ error: 'Failed to generate registration options' });
  }
};

/**
 * POST /api/v1/auth/parent/register/verify
 * Body: { userId: string, response: RegistrationResponseJSON, challenge: string, device_label?: string }
 * Verifies WebAuthn registration response, stores credential, returns JWT tokens.
 */
export const verifyRegistration = async (req: Request, res: Response): Promise<void> => {
  const { userId, response, challenge, device_label } = req.body;

  if (!userId || !response || !challenge) {
    logger.warn('Registration verify request missing fields');
    res.status(400).json({ error: 'userId, response, and challenge are required' });
    return;
  }

  try {
    const verification = await verifyAndStoreCredential(userId, response, challenge, device_label);

    if (!verification.verified) {
      logger.warn({ userId }, 'FIDO2 registration verification failed');
      res.status(401).json({ error: 'Registration verification failed' });
      return;
    }

    const payload: TokenPayload = {
      sub: userId,
      role: 'parent',
    };

    const tokens = generateTokenPair(payload);

    logger.info({ userId }, 'FIDO2 credential verified and stored');
    res.status(201).json({
      message: 'Biometric registration successful',
      credential_id: verification.credential_id,
      ...tokens,
    });
  } catch (error) {
    logger.error({ err: error }, 'Failed to verify registration');
    res.status(500).json({ error: 'Failed to verify registration' });
  }
};

/**
 * POST /api/v1/auth/student/login
 * Body: { handle: string, pin: string }
 * Authenticates student with handle and PIN.
 * Rate limited, account lockout after 5 failures.
 */
export const childLogin = async (req: Request, res: Response): Promise<void> => {
  const { handle, pin } = req.body;

  if (!handle || !pin || typeof handle !== 'string' || typeof pin !== 'string') {
    logger.warn('Student login request missing handle or pin');
    res.status(400).json({ error: 'Handle and PIN are required' });
    return;
  }

  try {
    const ipAddress = getClientIp(req);
    const userAgent = getUserAgent(req);

    const result = await studentLogin(handle, pin, ipAddress, userAgent);

    if (!result.success) {
      res.status(401).json({ error: result.error });
      return;
    }

    if (!result.user) {
      res.status(500).json({ error: 'An unexpected error occurred' });
      return;
    }

    const payload: TokenPayload = {
      sub: result.user.user_id,
      role: 'student',
      handle: result.user.user_handle,
    };

    const tokens = generateTokenPair(payload);

    logger.info({ userId: result.user.user_id }, 'Student logged in successfully');
    res.status(200).json({
      message: 'Login successful',
      user: {
        user_id: result.user.user_id,
        user_handle: result.user.user_handle,
        role: result.user.role,
      },
      ...tokens,
    });
  } catch (error) {
    logger.error({ err: error }, 'Student login failed unexpectedly');
    res.status(500).json({ error: 'An unexpected error occurred' });
  }
};

/**
 * POST /api/v1/auth/token/refresh
 * Body: { refreshToken: string }
 * Generates new access token from refresh token.
 */
export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  const { refreshToken } = req.body;

  if (!refreshToken || typeof refreshToken !== 'string') {
    logger.warn('Token refresh request missing refreshToken');
    res.status(400).json({ error: 'Refresh token is required' });
    return;
  }

  try {
    const { verifyAccessToken } = await import('../services/jwt.service');
    const decoded = verifyAccessToken(refreshToken);

    const payload: TokenPayload = {
      sub: decoded.sub,
      role: decoded.role,
      email: decoded.email,
      handle: decoded.handle,
    };

    const tokens = generateTokenPair(payload);

    logger.info({ sub: decoded.sub }, 'Token refreshed successfully');
    res.status(200).json(tokens);
  } catch (error) {
    logger.error({ err: error }, 'Token refresh failed');
    res.status(401).json({ error: 'Invalid or expired refresh token' });
  }
};