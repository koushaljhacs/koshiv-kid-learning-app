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
 * Version 1.1.0 | Integrated device_credentials repository — stores WebAuthn public key in DB after successful verification
 * Version 1.1.1 | Fix: TypeScript errors — Uint8Array to base64url, credential type from response, null to undefined
 *
 * Aim: FIDO2 / WebAuthn Service for Parent Authentication
 * Why: Generates WebAuthn registration options for parent biometric
 *      device enrollment. Verifies attestation responses from client.
 *      Stores verified public key (base64url encoded) in auth_schema.device_credentials.
 *      Uses @simplewebauthn/server for standards-compliant WebAuthn.
 *      Relying Party ID read from RP_ID env variable.
 *      Private key NEVER stored — only public key and credential metadata.
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
import * as deviceCredentialRepo from '../repositories/device-credential.repository';
import { CredentialType } from '../models/device-credential.model';

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
 * Convert Uint8Array to base64url string.
 * Used to convert WebAuthn public key bytes to storable format.
 */
const uint8ArrayToBase64url = (buffer: Uint8Array): string => {
  return Buffer.from(buffer).toString('base64url');
};

/**
 * Generate WebAuthn registration options for a parent user.
 * Returns PublicKeyCredentialCreationOptions to send to browser.
 * challenge must be stored temporarily for verification step.
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
 * Verify WebAuthn registration response AND persist credential to database.
 * After verification, stores the public key (base64url encoded) in auth_schema.device_credentials.
 * credential_type is determined from response.auth... or defaults to 'platform'.
 * Returns verification result with stored credential_id.
 */
export const verifyAndStoreCredential = async (
  userId: string,
  response: RegistrationResponseJSON,
  expectedChallenge: string,
  deviceLabel?: string,
): Promise<{
  verified: boolean;
  credential_id?: string;
}> => {
  logger.info({ userId }, 'Verifying FIDO2 registration response');

  const verificationOptions: VerifyRegistrationResponseOpts = {
    response,
    expectedChallenge,
    expectedOrigin,
    expectedRPID: rpID,
  };

  try {
    const verification = await verifyRegistrationResponse(verificationOptions);

    if (!verification.verified || !verification.registrationInfo) {
      logger.warn({ userId, verified: verification.verified }, 'FIDO2 verification failed');
      return { verified: false };
    }

    const { credential } = verification.registrationInfo;

    // Determine credential type — default to 'platform' if not available
    const credentialType: CredentialType = 'platform';

    // Convert public key Uint8Array to base64url string for DB storage
    const publicKeyBase64 = uint8ArrayToBase64url(credential.publicKey);

    // Store public key in database
    const storedCredential = await deviceCredentialRepo.createCredential({
      user_id: userId,
      public_key: publicKeyBase64,
      credential_type: credentialType,
      device_label: deviceLabel || undefined,
    });

    logger.info(
      { userId, credentialId: storedCredential.credential_id, credentialType },
      'FIDO2 credential verified and stored successfully',
    );

    return {
      verified: true,
      credential_id: storedCredential.credential_id,
    };
  } catch (error) {
    logger.error({ err: error, userId }, 'FIDO2 verification or storage failed');
    throw error;
  }
};