/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/models/device-credential.model.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial DeviceCredential model — mapping to auth_schema.device_credentials table
 *
 * Aim: FIDO2/WebAuthn Device Credential Interface
 * Why: Maps exactly to auth_schema.device_credentials table.
 *      Stores WebAuthn public key and credential metadata.
 *      Private key NEVER stored — only generated and held on user's device
 *      (Secure Enclave / TPM). Server stores public key for challenge verification.
 *      credential_type distinguishes platform authenticators (FaceID, fingerprint)
 *      from cross-platform authenticators (external security keys).
 * ============================================================
 */

export type CredentialType = 'platform' | 'cross-platform';

export interface DeviceCredential {
  credential_id: string;
  user_id: string;
  public_key: string;
  credential_type: CredentialType;
  device_label: string | null;
  last_used_at: string | null;
  created_at: string;
}

export interface CreateDeviceCredential {
  user_id: string;
  public_key: string;
  credential_type: CredentialType;
  device_label?: string;
}