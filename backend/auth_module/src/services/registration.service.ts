/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/services/registration.service.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Registration service — transactional parent+child creation, handle generation, FIDO2 persistence
 *
 * Aim: Parent Registration Orchestration with Transaction Safety
 * Why: Creates parent user, child user, both profiles, relationship,
 *      consent, and device credential in a SINGLE PostgreSQL transaction.
 *      If any step fails, entire block ROLLBACK — zero orphaned records.
 *      Generates cryptographically secure user_handle for both parent and child.
 *      Auto-generates 6-digit PIN for child login.
 * ============================================================
 */

import crypto from 'crypto';
import pool from '../config/db';
import pino from 'pino';
import { hashPassword, hashPin } from './auth.service';

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

export interface ParentRegistrationInput {
  parent_name: string;
  email: string;
  password: string;
  phone_number?: string;
  child_name: string;
  child_dob?: string;
  child_grade?: string;
}

export interface RegistrationResult {
  success: boolean;
  parent_user_id?: string;
  parent_handle?: string;
  child_user_id?: string;
  child_handle?: string;
  child_pin?: string;
  error?: string;
}

/**
 * Generate a unique user handle.
 * Format: prefix + 8 random lowercase alphanumeric characters.
 * Collision check: retries up to 5 times if handle exists.
 */
const generateHandle = async (prefix: string): Promise<string> => {
  const maxRetries = 5;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const randomPart = crypto
      .randomBytes(6)
      .toString('base64url')
      .toLowerCase()
      .slice(0, 8);

    const handle = `${prefix}${randomPart}`;

    // Check if handle exists
    const result = await pool.query(
      'SELECT 1 FROM auth_schema.users WHERE user_handle = $1',
      [handle],
    );

    if (result.rows.length === 0) {
      return handle;
    }

    logger.debug({ handle, attempt }, 'Handle collision — retrying');
  }

  throw new Error('Failed to generate unique handle after maximum retries');
};

/**
 * Generate a random 6-digit PIN for child login.
 */
const generateChildPin = (): string => {
  return crypto.randomInt(100000, 999999).toString();
};

/**
 * Complete parent + child registration in a single transaction.
 *
 * Steps:
 *   1. Hash password, generate handles and PIN
 *   2. BEGIN transaction
 *   3. INSERT parent into auth_schema.users
 *   4. INSERT parent profile into auth_schema.user_profiles
 *   5. INSERT child into auth_schema.users
 *   6. INSERT child profile into auth_schema.user_profiles
 *   7. INSERT relationship into auth_schema.user_relationships
 *   8. INSERT consent for parent into auth_schema.user_consents
 *   9. COMMIT (or ROLLBACK on any error)
 *
 * Returns handles and child PIN only on full success.
 * No partial data ever persisted.
 */
export const registerParentWithChild = async (
  input: ParentRegistrationInput,
): Promise<RegistrationResult> => {
  logger.info({ email: input.email }, 'Starting parent+child registration');

  // Generate values
  const passwordHash = await hashPassword(input.password);
  const childPin = generateChildPin();
  const childPinHash = hashPin(childPin);
  const parentHandle = await generateHandle('parent_');
  const childHandle = await generateHandle('student_');

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    logger.debug('Transaction BEGIN — inserting parent user');

    // Step 3: Insert parent user
    const parentResult = await client.query(
      `INSERT INTO auth_schema.users (user_handle, role, email, password_hash, phone_number)
       VALUES ($1, 'parent', $2, $3, $4)
       RETURNING user_id`,
      [parentHandle, input.email, passwordHash, input.phone_number || null],
    );
    const parentUserId: string = parentResult.rows[0].user_id;
    logger.debug({ parentUserId }, 'Parent user inserted');

    // Step 4: Insert parent profile
    await client.query(
      `INSERT INTO auth_schema.user_profiles (user_id, full_name)
       VALUES ($1, $2)`,
      [parentUserId, input.parent_name],
    );
    logger.debug({ parentUserId }, 'Parent profile inserted');

    // Step 5: Insert child user
    const childResult = await client.query(
      `INSERT INTO auth_schema.users (user_handle, role, pin_hash)
       VALUES ($1, 'student', $2)
       RETURNING user_id`,
      [childHandle, childPinHash],
    );
    const childUserId: string = childResult.rows[0].user_id;
    logger.debug({ childUserId }, 'Child user inserted');

    // Step 6: Insert child profile
    await client.query(
      `INSERT INTO auth_schema.user_profiles (user_id, full_name, date_of_birth, grade_class)
       VALUES ($1, $2, $3, $4)`,
      [
        childUserId,
        input.child_name,
        input.child_dob || null,
        input.child_grade || null,
      ],
    );
    logger.debug({ childUserId }, 'Child profile inserted');

    // Step 7: Insert relationship (parent is guardian of child)
    await client.query(
      `INSERT INTO auth_schema.user_relationships (student_id, guardian_id, relationship_type, is_primary)
       VALUES ($1, $2, 'custodian', TRUE)`,
      [childUserId, parentUserId],
    );
    logger.debug('Relationship inserted');

    // Step 8: Insert consent for parent
    await client.query(
      `INSERT INTO auth_schema.user_consents (user_id, terms_accepted, privacy_accepted)
       VALUES ($1, TRUE, TRUE)`,
      [parentUserId],
    );
    logger.debug('Consent inserted');

    await client.query('COMMIT');
    logger.info(
      { parentUserId, childUserId, parentHandle, childHandle },
      'Registration transaction COMMITTED successfully',
    );

    return {
      success: true,
      parent_user_id: parentUserId,
      parent_handle: parentHandle,
      child_user_id: childUserId,
      child_handle: childHandle,
      child_pin: childPin,
    };
  } catch (error) {
    await client.query('ROLLBACK');
    logger.error(
      { err: error, email: input.email },
      'Registration transaction ROLLBACK — all changes discarded',
    );
    return {
      success: false,
      error: 'Registration failed. Please try again.',
    };
  } finally {
    client.release();
  }
};

/**
 * Store FIDO2 credential after successful registration.
 * Called separately because WebAuthn requires browser interaction
 * which cannot be part of the same DB transaction.
 */
export const storeFido2CredentialForUser = async (
  userId: string,
  publicKey: string,
  credentialType: 'platform' | 'cross-platform',
  deviceLabel?: string,
): Promise<string> => {
  const client = await pool.connect();

  try {
    const result = await client.query(
      `INSERT INTO auth_schema.device_credentials (user_id, public_key, credential_type, device_label)
       VALUES ($1, $2, $3, $4)
       RETURNING credential_id`,
      [userId, publicKey, credentialType, deviceLabel || null],
    );

    logger.info({ userId, credentialType }, 'FIDO2 credential stored');
    return result.rows[0].credential_id;
  } catch (error) {
    logger.error({ err: error, userId }, 'Failed to store FIDO2 credential');
    throw error;
  } finally {
    client.release();
  }
};