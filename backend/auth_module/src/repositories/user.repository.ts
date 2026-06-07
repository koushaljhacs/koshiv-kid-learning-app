/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/repositories/user.repository.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial User repository — parameterized queries for auth_schema.users CRUD
 *
 * Aim: User Database Operations
 * Why: All user-related PostgreSQL queries live here.
 *      Uses parameterized queries exclusively — zero string concatenation.
 *      Prevents SQL injection by design. Error messages never expose query values.
 *      Schema-qualified table names (auth_schema.users) ensure correct routing.
 * ============================================================
 */

import pool from '../config/db';
import { User, CreateParentUser, CreateStudentUser, UserRole } from '../models/user.model';

/**
 * Find a user by email.
 * Used for parent login — email is unique per CHECK constraint.
 * Returns null if not found.
 */
export const findUserByEmail = async (email: string): Promise<User | null> => {
  const query = `
    SELECT user_id, user_handle, role, phone_number, email,
           password_hash, pin_hash, is_active, failed_login_attempts,
           locked_until, last_login, created_at, updated_at
    FROM auth_schema.users
    WHERE email = $1
  `;

  const result = await pool.query(query, [email]);

  if (result.rows.length === 0) {
    return null;
  }

  return result.rows[0];
};

/**
 * Find a user by handle.
 * Used for student login — handle is unique per UNIQUE constraint.
 * Returns null if not found.
 */
export const findUserByHandle = async (handle: string): Promise<User | null> => {
  const query = `
    SELECT user_id, user_handle, role, phone_number, email,
           password_hash, pin_hash, is_active, failed_login_attempts,
           locked_until, last_login, created_at, updated_at
    FROM auth_schema.users
    WHERE user_handle = $1
  `;

  const result = await pool.query(query, [handle]);

  if (result.rows.length === 0) {
    return null;
  }

  return result.rows[0];
};

/**
 * Find a user by ID.
 * Used for token verification and profile lookups.
 */
export const findUserById = async (userId: string): Promise<User | null> => {
  const query = `
    SELECT user_id, user_handle, role, phone_number, email,
           password_hash, pin_hash, is_active, failed_login_attempts,
           locked_until, last_login, created_at, updated_at
    FROM auth_schema.users
    WHERE user_id = $1
  `;

  const result = await pool.query(query, [userId]);

  if (result.rows.length === 0) {
    return null;
  }

  return result.rows[0];
};

/**
 * Create a parent user.
 * Inserts into auth_schema.users with role='parent'.
 * Password is pre-hashed before calling this function.
 * Returns the newly created user.
 */
export const createParentUser = async (data: CreateParentUser): Promise<User> => {
  const query = `
    INSERT INTO auth_schema.users (user_handle, role, email, password_hash, phone_number)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING user_id, user_handle, role, phone_number, email,
              password_hash, pin_hash, is_active, failed_login_attempts,
              locked_until, last_login, created_at, updated_at
  `;

  const values = [
    data.user_handle,
    'parent' as UserRole,
    data.email,
    data.password_hash,
    data.phone_number || null,
  ];

  const result = await pool.query(query, values);
  return result.rows[0];
};

/**
 * Create a student user.
 * Inserts into auth_schema.users with role='student'.
 * PIN is pre-hashed before calling this function.
 * Returns the newly created user.
 */
export const createStudentUser = async (data: CreateStudentUser): Promise<User> => {
  const query = `
    INSERT INTO auth_schema.users (user_handle, role, pin_hash)
    VALUES ($1, $2, $3)
    RETURNING user_id, user_handle, role, phone_number, email,
              password_hash, pin_hash, is_active, failed_login_attempts,
              locked_until, last_login, created_at, updated_at
  `;

  const values = [
    data.user_handle,
    'student' as UserRole,
    data.pin_hash,
  ];

  const result = await pool.query(query, values);
  return result.rows[0];
};

/**
 * Update last_login timestamp.
 * Called after successful authentication.
 */
export const updateLastLogin = async (userId: string): Promise<void> => {
  const query = `
    UPDATE auth_schema.users
    SET last_login = NOW(),
        updated_at = NOW()
    WHERE user_id = $1
  `;

  await pool.query(query, [userId]);
};

/**
 * Increment failed login attempts.
 * Called after failed authentication.
 * If attempts reach threshold, sets locked_until.
 */
export const incrementFailedAttempts = async (userId: string, threshold: number = 5): Promise<void> => {
  const query = `
    UPDATE auth_schema.users
    SET failed_login_attempts = failed_login_attempts + 1,
        locked_until = CASE
          WHEN failed_login_attempts + 1 >= $2
          THEN NOW() + INTERVAL '15 minutes'
          ELSE NULL
        END,
        updated_at = NOW()
    WHERE user_id = $1
  `;

  await pool.query(query, [userId, threshold]);
};

/**
 * Reset failed login attempts and unlock account.
 * Called after successful authentication.
 */
export const resetFailedAttempts = async (userId: string): Promise<void> => {
  const query = `
    UPDATE auth_schema.users
    SET failed_login_attempts = 0,
        locked_until = NULL,
        updated_at = NOW()
    WHERE user_id = $1
  `;

  await pool.query(query, [userId]);
};

/**
 * Check if user account is locked.
 * Returns true if locked_until is set and in the future.
 */
export const isAccountLocked = async (userId: string): Promise<boolean> => {
  const query = `
    SELECT locked_until
    FROM auth_schema.users
    WHERE user_id = $1
  `;

  const result = await pool.query(query, [userId]);

  if (result.rows.length === 0) {
    return false;
  }

  const { locked_until } = result.rows[0];

  if (!locked_until) {
    return false;
  }

  return new Date(locked_until) > new Date();
};