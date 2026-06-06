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
 * Version 1.1.0 | Integrated auth.service.ts — real DB login for parent (email+password) and student (handle+PIN), rate limiting, audit logging
 *
 * Aim: Authentication HTTP Request/Response Handler
 * Why: Handles parent login (email+password), student login (handle+PIN),
 *      parent registration (FIDO2/WebAuthn), and token refresh.
 *      Delegates business logic to auth.service.ts, jwt.service.ts, and fido2.service.ts.
 *      Never exposes internal error details to client.
 * ============================================================
 */

import { Request, Response } from 'express';
import pino from 'pino';
import { generateTokenPair, TokenPayload } from '../services/jwt.service';
import { parentLogin, studentLogin } from '../services/auth.service';
import { generateFido2RegistrationOptions, verifyFido2RegistrationResponse } from '../services/fido2.service';

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
 * Body: { email: string, response: RegistrationResponseJSON, challenge: string }
 * Verifies WebAuthn registration response and returns JWT tokens.
 */
export const verifyRegistration = async (req: Request, res: Response): Promise<void> => {
  const { email, response, challenge } = req.body;

  if (!email || !response || !challenge) {
    logger.warn('Registration verify request missing fields');
    res.status(400).json({ error: 'Email, response, and challenge are required' });
    return;
  }

  try {
    const verification = await verifyFido2RegistrationResponse(response, challenge);

    if (!verification.verified) {
      logger.warn({ email }, 'FIDO2 registration verification failed');
      res.status(401).json({ error: 'Registration verification failed' });
      return;
    }

    const payload: TokenPayload = {
      sub: `parent_${Date.now()}`,
      role: 'parent',
      email,
    };

    const tokens = generateTokenPair(payload);

    logger.info({ email }, 'Parent registered successfully');
    res.status(201).json({
      message: 'Parent registered successfully',
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