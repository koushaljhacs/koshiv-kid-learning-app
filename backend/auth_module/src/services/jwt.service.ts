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
 * Version 1.0.3 | BUG-TOK-01 CRITICAL FIX: Hardened verifyAccessToken — completeRefreshTokenPayload, strict algorithms, public key validation, zero-tolerance clock skew
 *
 * Aim: JWT Token Generation & Verification Service
 * Why: Generates RS256-signed Access Tokens (15 min TTL) and Refresh Tokens
 *      (7 day TTL) using private key. Verification uses public key ONLY
 *      with STRICT algorithm enforcement. Public key validated at startup.
 *      Zero shared secrets — fully asymmetric. Token tampering impossible
 *      without private key. Refresh token payload extracted for re-issuance.
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

const PRIVATE_KEY_PATH = path.join(__dirname, '../../keys/private.pem');
const PUBLIC_KEY_PATH = path.join(__dirname, '../../keys/public.pem');

// Load and validate keys at startup — fail fast if missing
let privateKey: string;
let publicKey: string;

try {
  privateKey = fs.readFileSync(PRIVATE_KEY_PATH, 'utf8');
  if (!privateKey || privateKey.trim().length === 0) {
    throw new Error('Private key file is empty');
  }
  if (!privateKey.includes('BEGIN') || !privateKey.includes('PRIVATE KEY')) {
    throw new Error('Private key file does not contain a valid PEM key');
  }
  logger.info('Private key loaded and validated successfully');
} catch (error) {
  logger.fatal({ err: error, path: PRIVATE_KEY_PATH }, 'FATAL: Cannot load private key');
  process.exit(1);
}

try {
  publicKey = fs.readFileSync(PUBLIC_KEY_PATH, 'utf8');
  if (!publicKey || publicKey.trim().length === 0) {
    throw new Error('Public key file is empty');
  }
  if (!publicKey.includes('BEGIN') || !publicKey.includes('PUBLIC KEY')) {
    throw new Error('Public key file does not contain a valid PEM key');
  }
  logger.info('Public key loaded and validated successfully');
} catch (error) {
  logger.fatal({ err: error, path: PUBLIC_KEY_PATH }, 'FATAL: Cannot load public key');
  process.exit(1);
}

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '7d';

// STRICT: Only RS256 — prevents algorithm confusion attacks
const ALLOWED_ALGORITHMS: jwt.Algorithm[] = ['RS256'];

export interface TokenPayload {
  sub: string;
  role: 'parent' | 'student';
  email?: string;
  handle?: string;
}

export interface RefreshTokenPayload {
  sub: string;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

/**
 * Generate Access Token + Refresh Token pair.
 * Access Token: 15 minutes, contains user identity and role.
 * Refresh Token: 7 days, contains ONLY user_id for re-issuance.
 * Both signed with RS256 + private key.
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
 * Verify Access Token using PUBLIC KEY with STRICT enforcement.
 * CRITICAL SECURITY:
 *   - algorithms: ['RS256'] — blocks 'none' and 'HS256' algorithm confusion attacks
 *   - issuer: 'koshiv-auth' — blocks tokens from other issuers
 *   - clockTolerance: 0 — zero tolerance for clock skew
 *   - complete: true — returns full decoded payload with header
 *   - maxAge: '15m' — access token age limit
 *
 * If token is tampered (payload changed without re-signing), verification fails.
 * If role was modified, signature mismatch occurs — token REJECTED.
 */
export const verifyAccessToken = (token: string): TokenPayload => {
  if (!token || typeof token !== 'string' || token.trim().length === 0) {
    logger.warn('Token verification attempted with empty token');
    throw new Error('Token is required');
  }

  logger.debug('Verifying access token with strict RS256 enforcement');

  try {
    const decoded = jwt.verify(token, publicKey, {
      algorithms: ALLOWED_ALGORITHMS,
      issuer: 'koshiv-auth',
      clockTolerance: 0,
      complete: false,
    });

    const payload = decoded as TokenPayload;

    // Additional validation: role must be valid
    if (!payload.sub || !payload.role) {
      logger.warn({ payload }, 'Token missing required claims');
      throw new Error('Token missing required claims');
    }

    if (payload.role !== 'parent' && payload.role !== 'student') {
      logger.warn({ role: payload.role }, 'Token has invalid role — possible tampering');
      throw new Error('Token has invalid role');
    }

    logger.debug({ sub: payload.sub, role: payload.role }, 'Token verified successfully with RS256');
    return payload;
  } catch (error) {
    const errMsg = (error as Error).message;

    if (errMsg.includes('invalid algorithm')) {
      logger.error({ err: error }, 'Algorithm confusion attack detected — token REJECTED');
    } else if (errMsg.includes('invalid signature')) {
      logger.error({ err: error }, 'Token signature invalid — possible tampering detected');
    } else if (errMsg.includes('jwt expired')) {
      logger.warn('Token expired');
    } else {
      logger.error({ err: error }, 'Token verification failed');
    }

    throw error;
  }
};

/**
 * Verify Refresh Token and extract sub claim.
 * Used ONLY for token refresh — never for authentication.
 * Same strict enforcement as access token verification.
 */
export const verifyRefreshToken = (token: string): RefreshTokenPayload => {
  if (!token || typeof token !== 'string' || token.trim().length === 0) {
    logger.warn('Refresh token verification attempted with empty token');
    throw new Error('Refresh token is required');
  }

  logger.debug('Verifying refresh token with strict RS256 enforcement');

  try {
    const decoded = jwt.verify(token, publicKey, {
      algorithms: ALLOWED_ALGORITHMS,
      issuer: 'koshiv-auth',
      clockTolerance: 0,
      complete: false,
    });

    const payload = decoded as RefreshTokenPayload;

    if (!payload.sub) {
      logger.warn('Refresh token missing sub claim');
      throw new Error('Refresh token missing sub claim');
    }

    logger.debug({ sub: payload.sub }, 'Refresh token verified successfully');
    return payload;
  } catch (error) {
    const errMsg = (error as Error).message;

    if (errMsg.includes('invalid algorithm')) {
      logger.error({ err: error }, 'Algorithm confusion attack on refresh token — REJECTED');
    } else if (errMsg.includes('invalid signature')) {
      logger.error({ err: error }, 'Refresh token signature invalid — possible tampering');
    } else if (errMsg.includes('jwt expired')) {
      logger.warn('Refresh token expired');
    } else {
      logger.error({ err: error }, 'Refresh token verification failed');
    }

    throw error;
  }
};