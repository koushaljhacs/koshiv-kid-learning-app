/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/models/user.model.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial User model — TypeScript interface mapping to auth_schema.users table
 *
 * Aim: User TypeScript Interface
 * Why: Maps exactly to auth_schema.users table columns.
 *      Provides type safety for all user-related database operations.
 *      Role-based constraints enforced at DB level via CHECK constraints.
 * ============================================================
 */

export type UserRole = 'admin' | 'parent' | 'student';

export interface User {
  user_id: string;
  user_handle: string;
  role: UserRole;
  phone_number: string | null;
  email: string | null;
  password_hash: string | null;
  pin_hash: string | null;
  is_active: boolean;
  failed_login_attempts: number;
  locked_until: string | null;
  last_login: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateParentUser {
  user_handle: string;
  email: string;
  password_hash: string;
  phone_number?: string;
}

export interface CreateStudentUser {
  user_handle: string;
  pin_hash: string;
}