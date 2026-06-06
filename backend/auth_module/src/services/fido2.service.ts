/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/services/fido2.service.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial FIDO2/WebAuthn service — registration options generation and response verification scaffolding
 * Version 1.0.1 | Fix: Replaced 'any' with RegistrationResponseJSON type, added Pino logging
 *
 * Aim: FIDO2 / WebAuthn Service for Parent Authentication
 * Why: Generates WebAuthn registration options for parent biometric/PIN
 *      device enrollment. Verifies attestation responses from client.
 *      Uses @simplewebauthn/server for standards-compliant WebAuthn.
 *      Relying Party ID read from RP_ID env variable (localhost for dev).
 * ============================================================
 */

import {
  generateRegistrationOptions,
  verifyRegistrationResponse,
} from '@simplewebauthn/server';
import type {
  GenerateRegistrationOptionsOpts,
  VerifyRegistrationResponseOpts,
  RegistrationResponseJSON,
} from '@simplewebauthn/server';
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

const rpID = process.env.RP_ID || 'localhost';
const rpName = 'koshiv - Sovereign Edu Platform';
const expectedOrigin = `https://${rpID}`;

/**
 * Generate WebAuthn registration options for a parent user.
 * Returns PublicKeyCredentialCreationOptions to send to browser.
 */
export const generateFido2RegistrationOptions = async (
  userId: string,
  userEmail: string,
): Promise<ReturnType<typeof generateRegistrationOptions>> => {
  logger.info({ userId, userEmail }, 'Generating FIDO2 registration options');

  const options: GenerateRegistrationOptionsOpts = {
    rpName,
    rpID,
    userName: userEmail,
    userDisplayName: userEmail,
    attestationType: 'none',
    authenticatorSelection: {
      residentKey: 'preferred',
      userVerification: 'preferred',
    },
  };

  const registrationOptions = await generateRegistrationOptions(options);

  logger.debug({ userId }, 'FIDO2 registration options generated successfully');
  return registrationOptions;
};

/**
 * Verify WebAuthn registration response from browser.
 * Returns verification result with registration info on success.
 */
export const verifyFido2RegistrationResponse = async (
  response: RegistrationResponseJSON,
  expectedChallenge: string,
): Promise<ReturnType<typeof verifyRegistrationResponse>> => {
  logger.info('Verifying FIDO2 registration response');

  const verificationOptions: VerifyRegistrationResponseOpts = {
    response,
    expectedChallenge,
    expectedOrigin,
    expectedRPID: rpID,
  };

  try {
    const verification = await verifyRegistrationResponse(verificationOptions);
    logger.info({ verified: verification.verified }, 'FIDO2 verification completed');
    return verification;
  } catch (error) {
    logger.error({ err: error }, 'FIDO2 verification failed');
    throw error;
  }
};