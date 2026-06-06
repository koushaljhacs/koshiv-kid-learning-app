/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/services/jwt.service.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial JWT service — RS256 asymmetric, access token 15min, refresh token 7d
 * Version 1.0.1 | Fix: verifyAccessToken now uses public key exclusively, added Pino logging
 * Version 1.0.2 | Fix: Removed duplicate 'subject' option from jwt.sign — payload already contains 'sub' field
 *
 * Aim: JWT Token Generation & Verification Service
 * Why: Generates RS256-signed Access Tokens (15 min TTL) and Refresh Tokens
 *      (7 day TTL) using private key. Verification uses public key only.
 *      Zero shared secrets — fully asymmetric. Spring Boot services verify
 *      using the same public key.
 *      'sub' claim is only in payload, not duplicated in options.
 * ============================================================
 */

import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import pino from 'pino';

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

const privateKey = fs.readFileSync(
  path.join(__dirname, '../../keys/private.pem'),
  'utf8',
);

const publicKey = fs.readFileSync(
  path.join(__dirname, '../../keys/public.pem'),
  'utf8',
);

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '7d';

export interface TokenPayload {
  sub: string;
  role: 'parent' | 'student';
  email?: string;
  handle?: string;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

/**
 * Generate Access Token + Refresh Token pair.
 * Access Token: 15 minutes, contains user identity and role.
 * Refresh Token: 7 days, contains only user_id for re-issuance.
 * 'sub' is in payload — NOT duplicated in options to avoid jwt.sign conflict.
 */
export const generateTokenPair = (payload: TokenPayload): TokenPair => {
  logger.info({ sub: payload.sub, role: payload.role }, 'Generating token pair');

  const accessToken = jwt.sign(payload, privateKey, {
    algorithm: 'RS256',
    expiresIn: ACCESS_TOKEN_TTL,
    issuer: 'koshiv-auth',
  });

  const refreshToken = jwt.sign(
    { sub: payload.sub },
    privateKey,
    {
      algorithm: 'RS256',
      expiresIn: REFRESH_TOKEN_TTL,
      issuer: 'koshiv-auth',
    },
  );

  logger.debug({ sub: payload.sub }, 'Token pair generated successfully');
  return { accessToken, refreshToken };
};

/**
 * Generate only an Access Token (for re-authentication flows).
 */
export const generateAccessToken = (payload: TokenPayload): string => {
  logger.info({ sub: payload.sub }, 'Generating access token');

  const accessToken = jwt.sign(payload, privateKey, {
    algorithm: 'RS256',
    expiresIn: ACCESS_TOKEN_TTL,
    issuer: 'koshiv-auth',
  });

  logger.debug({ sub: payload.sub }, 'Access token generated successfully');
  return accessToken;
};

/**
 * Verify Access Token using PUBLIC KEY and return decoded payload.
 * Throws if token is invalid or expired — caller must handle.
 */
export const verifyAccessToken = (token: string): TokenPayload => {
  logger.debug('Verifying access token');

  try {
    const decoded = jwt.verify(token, publicKey, {
      algorithms: ['RS256'],
      issuer: 'koshiv-auth',
    });

    logger.debug({ sub: (decoded as TokenPayload).sub }, 'Token verified successfully');
    return decoded as TokenPayload;
  } catch (error) {
    logger.error({ err: error }, 'Token verification failed');
    throw error;
  }
};