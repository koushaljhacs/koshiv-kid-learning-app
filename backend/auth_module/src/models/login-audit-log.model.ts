/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/models/login-audit-log.model.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial LoginAuditLog model — mapping to auth_schema.login_audit_logs table
 *
 * Aim: Login Audit Log TypeScript Interface
 * Why: Maps exactly to auth_schema.login_audit_logs table.
 *      Immutable audit trail for ALL authentication events.
 *      Captures event type, attempt status, failure reason, and request metadata.
 *      user_id is nullable — captures attempts on non-existent accounts.
 *      Enables real-time threat detection, forensic investigation,
 *      and regulatory compliance reporting without losing audit records.
 * ============================================================
 */

export type AuditEventType =
  | 'login_success'
  | 'login_failed'
  | 'login_locked'
  | 'password_reset'
  | 'pin_reset'
  | 'account_created'
  | 'account_deactivated'
  | 'account_reactivated'
  | 'logout'
  | 'token_refresh'
  | 'biometric_registered'
  | 'biometric_removed';

export type AttemptStatus = 'success' | 'failure';

export interface LoginAuditLog {
  log_id: string;
  user_id: string | null;
  event_type: AuditEventType;
  ip_address: string | null;
  location_data: Record<string, unknown> | null;
  user_agent: string | null;
  attempt_status: AttemptStatus;
  failure_reason: string | null;
  created_at: string;
}

export interface CreateLoginAuditLog {
  user_id?: string | null;
  event_type: AuditEventType;
  ip_address?: string;
  location_data?: Record<string, unknown>;
  user_agent?: string;
  attempt_status: AttemptStatus;
  failure_reason?: string;
}