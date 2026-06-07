/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/repositories/login-audit-log.repository.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial LoginAuditLog repository — parameterized queries for auth_schema.login_audit_logs
 *
 * Aim: Authentication Audit Trail Database Operations
 * Why: All login_audit_logs table queries live here.
 *      Immutable audit trail — INSERT only, no UPDATE or DELETE.
 *      Captures every authentication event for threat detection and compliance.
 *      user_id is nullable to record attempts on non-existent accounts.
 *      Uses parameterized queries exclusively — zero string concatenation.
 * ============================================================
 */

import pool from '../config/db';
import { LoginAuditLog, CreateLoginAuditLog } from '../models/login-audit-log.model';

/**
 * Insert a new audit log entry.
 * This is the ONLY operation — audit logs are immutable.
 * user_id is optional to support logging attempts on non-existent accounts.
 */
export const createAuditLog = async (data: CreateLoginAuditLog): Promise<LoginAuditLog> => {
  const query = `
    INSERT INTO auth_schema.login_audit_logs
      (user_id, event_type, ip_address, location_data, user_agent, attempt_status, failure_reason)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING log_id, user_id, event_type, ip_address, location_data,
              user_agent, attempt_status, failure_reason, created_at
  `;

  const values = [
    data.user_id || null,
    data.event_type,
    data.ip_address || null,
    data.location_data ? JSON.stringify(data.location_data) : null,
    data.user_agent || null,
    data.attempt_status,
    data.failure_reason || null,
  ];

  const result = await pool.query(query, values);
  return result.rows[0];
};

/**
 * Get recent failed login attempts for a user.
 * Used for rate limiting and brute-force detection.
 * Returns count of failures in the specified time window.
 */
export const getRecentFailedAttempts = async (
  userId: string,
  windowMinutes: number = 15,
): Promise<number> => {
  const query = `
    SELECT COUNT(*) AS attempt_count
    FROM auth_schema.login_audit_logs
    WHERE user_id = $1
      AND event_type = 'login_failed'
      AND created_at > NOW() - INTERVAL '1 minute' * $2
  `;

  const result = await pool.query(query, [userId, windowMinutes]);
  return parseInt(result.rows[0].attempt_count, 10);
};

/**
 * Get recent audit logs for a user.
 * Used for security review and account activity display.
 */
export const getAuditLogsByUserId = async (
  userId: string,
  limit: number = 20,
): Promise<LoginAuditLog[]> => {
  const query = `
    SELECT log_id, user_id, event_type, ip_address, location_data,
           user_agent, attempt_status, failure_reason, created_at
    FROM auth_schema.login_audit_logs
    WHERE user_id = $1
    ORDER BY created_at DESC
    LIMIT $2
  `;

  const result = await pool.query(query, [userId, limit]);
  return result.rows;
};