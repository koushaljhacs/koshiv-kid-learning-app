/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/models/user-consent.model.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial UserConsent model — mapping to auth_schema.user_consents table
 *
 * Aim: User Consent TypeScript Interface
 * Why: Maps exactly to auth_schema.user_consents table.
 *      Stores all legal and functional permissions accepted during onboarding.
 *      Separated from users table for independent versioning, revocation, and audit.
 *      Critical for COPPA compliance (verifiable parental consent) and DPDP Act.
 *      Each consent (terms, privacy, notifications, camera, microphone, storage)
 *      can be individually managed without altering core account state.
 * ============================================================
 */

export interface UserConsent {
  consent_id: string;
  user_id: string;
  terms_accepted: boolean;
  privacy_accepted: boolean;
  notifications_allowed: boolean;
  camera_allowed: boolean;
  microphone_allowed: boolean;
  storage_allowed: boolean;
  accepted_at: string;
  updated_at: string;
}

export interface CreateUserConsent {
  user_id: string;
  terms_accepted?: boolean;
  privacy_accepted?: boolean;
  notifications_allowed?: boolean;
  camera_allowed?: boolean;
  microphone_allowed?: boolean;
  storage_allowed?: boolean;
}