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
 *
 * Aim: JWT Token Generation & Verification Service
 * Why: Generates RS256-signed Access Tokens (15 min TTL) and Refresh Tokens
 *      (7 day TTL) using private key. Spring Boot services verify using
 *      public key. Zero shared secrets — fully asymmetric.
 * ============================================================
 */

import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';

const privateKey = fs.readFileSync(
  path.join(__dirname, '../../keys/private.pem'),
  'utf8',
);

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '7d';

export interface TokenPayload {
  sub: string; // user_id
  role: 'parent' | 'child';
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
 */
export const generateTokenPair = (payload: TokenPayload): TokenPair => {
  const accessToken = jwt.sign(payload, privateKey, {
    algorithm: 'RS256',
    expiresIn: ACCESS_TOKEN_TTL,
    issuer: 'koshiv-auth',
    subject: payload.sub,
  });

  const refreshToken = jwt.sign(
    { sub: payload.sub },
    privateKey,
    {
      algorithm: 'RS256',
      expiresIn: REFRESH_TOKEN_TTL,
      issuer: 'koshiv-auth',
      subject: payload.sub,
    },
  );

  return { accessToken, refreshToken };
};

/**
 * Generate only an Access Token (for re-authentication flows).
 */
export const generateAccessToken = (payload: TokenPayload): string => {
  return jwt.sign(payload, privateKey, {
    algorithm: 'RS256',
    expiresIn: ACCESS_TOKEN_TTL,
    issuer: 'koshiv-auth',
    subject: payload.sub,
  });
};

/**
 * Verify Access Token and return decoded payload.
 * Throws if token is invalid or expired — caller must handle.
 */
export const verifyAccessToken = (token: string): TokenPayload => {
  const decoded = jwt.verify(token, privateKey, {
    algorithms: ['RS256'],
    issuer: 'koshiv-auth',
  });

  return decoded as TokenPayload;
};