/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/models/user-profile.model.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial UserProfile model — mapping to auth_schema.user_profiles table
 *
 * Aim: User Profile TypeScript Interface
 * Why: Maps exactly to auth_schema.user_profiles table.
 *      Stores PII (name, DOB, address) separate from auth credentials.
 *      Separation enables GDPR/COPPA compliance — PII can be exported
 *      or deleted without touching authentication data.
 *      grade_class tracks student education level for content personalization.
 * ============================================================
 */

export interface UserProfile {
  profile_id: string;
  user_id: string;
  full_name: string;
  date_of_birth: string | null;
  grade_class: string | null;
  avatar_url: string | null;
  state: string | null;
  city: string | null;
  pincode: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateUserProfile {
  user_id: string;
  full_name: string;
  date_of_birth?: string;
  grade_class?: string;
  state?: string;
  city?: string;
  pincode?: string;
}