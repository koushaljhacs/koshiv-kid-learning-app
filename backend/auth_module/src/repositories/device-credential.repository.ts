/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/repositories/device-credential.repository.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial DeviceCredential repository — parameterized queries for auth_schema.device_credentials
 *
 * Aim: FIDO2 Device Credential Database Operations
 * Why: All device_credentials table queries live here.
 *      Stores WebAuthn public keys for passwordless authentication.
 *      Uses parameterized queries exclusively — zero string concatenation.
 *      Public key is stored as text; private key NEVER touches server.
 *      credential_type distinguishes platform (FaceID) from cross-platform (YubiKey).
 * ============================================================
 */

import pool from '../config/db';
import { DeviceCredential, CreateDeviceCredential } from '../models/device-credential.model';

/**
 * Store a new WebAuthn device credential.
 * Called after successful FIDO2 registration verification.
 * Public key is the only cryptographic material stored.
 */
export const createCredential = async (data: CreateDeviceCredential): Promise<DeviceCredential> => {
  const query = `
    INSERT INTO auth_schema.device_credentials (user_id, public_key, credential_type, device_label)
    VALUES ($1, $2, $3, $4)
    RETURNING credential_id, user_id, public_key, credential_type,
              device_label, last_used_at, created_at
  `;

  const values = [
    data.user_id,
    data.public_key,
    data.credential_type,
    data.device_label || null,
  ];

  const result = await pool.query(query, values);
  return result.rows[0];
};

/**
 * Find all credentials registered by a user.
 * A user may have multiple devices registered.
 */
export const findCredentialsByUserId = async (userId: string): Promise<DeviceCredential[]> => {
  const query = `
    SELECT credential_id, user_id, public_key, credential_type,
           device_label, last_used_at, created_at
    FROM auth_schema.device_credentials
    WHERE user_id = $1
    ORDER BY created_at DESC
  `;

  const result = await pool.query(query, [userId]);
  return result.rows;
};

/**
 * Update last_used_at timestamp when credential is used for login.
 */
export const updateCredentialUsage = async (credentialId: string): Promise<void> => {
  const query = `
    UPDATE auth_schema.device_credentials
    SET last_used_at = NOW()
    WHERE credential_id = $1
  `;

  await pool.query(query, [credentialId]);
};

/**
 * Remove a device credential.
 * Called when user removes a registered device.
 */
export const deleteCredential = async (credentialId: string, userId: string): Promise<void> => {
  const query = `
    DELETE FROM auth_schema.device_credentials
    WHERE credential_id = $1 AND user_id = $2
  `;

  await pool.query(query, [credentialId, userId]);
};