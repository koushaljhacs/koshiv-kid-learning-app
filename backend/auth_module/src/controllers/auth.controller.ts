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
 *
 * Aim: Authentication HTTP Request/Response Handler
 * Why: Handles parent registration (FIDO2/WebAuthn) and child login
 *      (handle + PIN) HTTP requests. Delegates business logic to
 *      otp.service.ts, jwt.service.ts, and fido2.service.ts.
 * ============================================================
 */

import { Request, Response } from 'express';
import pino from 'pino';
import { generateTokenPair, TokenPayload } from '../services/jwt.service';
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
    const userId = `parent_${Date.now()}`; // Temporary — will be DB user ID in production
    const options = await generateFido2RegistrationOptions(userId, email);

    logger.info({ email }, 'FIDO2 registration options generated');
    res.status(200).json(options);
  } catch (error) {
    logger.error({ err: error, email }, 'Failed to generate registration options');
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
      sub: `parent_${Date.now()}`, // TODO: Replace with actual DB user ID
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
    logger.error({ err: error, email }, 'Failed to verify registration');
    res.status(500).json({ error: 'Failed to verify registration' });
  }
};

/**
 * POST /api/v1/auth/child/login
 * Body: { handle: string, pin: string }
 * Validates child handle and PIN, returns JWT tokens.
 * TODO: PIN validation against PostgreSQL (not yet implemented — Step 4 DB integration)
 */
export const childLogin = async (req: Request, res: Response): Promise<void> => {
  const { handle, pin } = req.body;

  if (!handle || !pin || typeof handle !== 'string' || typeof pin !== 'string') {
    logger.warn('Child login request missing handle or pin');
    res.status(400).json({ error: 'Handle and PIN are required' });
    return;
  }

  try {
    // TODO: Validate handle + PIN against PostgreSQL users table
    // Placeholder logic for now
    if (pin.length < 4) {
      logger.warn({ handle }, 'Child login failed — invalid PIN');
      res.status(401).json({ error: 'Invalid handle or PIN' });
      return;
    }

    const payload: TokenPayload = {
      sub: `child_${handle}`, // TODO: Replace with actual DB user ID
      role: 'child',
      handle,
    };

    const tokens = generateTokenPair(payload);

    logger.info({ handle }, 'Child logged in successfully');
    res.status(200).json({
      message: 'Child logged in successfully',
      ...tokens,
    });
  } catch (error) {
    logger.error({ err: error, handle }, 'Failed to login child');
    res.status(500).json({ error: 'Failed to login' });
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