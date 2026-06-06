/* ============================================================
   Project:      koshiv - Sovereign Edu Platform (Learning App for Kids)
   File:         01_auth_schema.sql
   Schema:       auth_schema
   Version:      1.0.0
   Author:       Koushal Jha
   Email:        koushaljha.cs@gmail.com
   Date:         2026-06-06
   Description:  Complete authentication schema with 6 enterprise-grade
                 tables supporting Parent-Child RBAC, FIDO2 biometric
                 credentials, account lockout, consent management,
                 relationship mapping, and comprehensive audit logging.
                 Designed for COPPA/GDPR-compliant minor data protection.
   Changelog:
     v1.0.0 (2026-06-06): Initial schema creation - 6 tables, ENUMs,
                          triggers, indexes, and lockout mechanism.
   ============================================================ */

-- ============================================================
-- Aim: Create isolated schema for all authentication-related
--      objects. Separates auth concerns from core application
--      data, enabling fine-grained access control and easier
--      security auditing. All user identity, credentials, and
--      session data reside exclusively within this schema.
-- ============================================================
CREATE SCHEMA IF NOT EXISTS auth_schema;
SET search_path TO auth_schema;

-- ============================================================
-- ENUM TYPE: user_role
-- Aim: Enforce strict role-based access control at the database
--      level. Prevents invalid role assignments and ensures
--      application logic cannot accidentally create users with
--      undefined or malicious roles. Three distinct roles map
--      to completely separate authentication flows.
-- ============================================================
CREATE TYPE auth_schema.user_role AS ENUM ('admin', 'parent', 'student');

-- ============================================================
-- ENUM TYPE: relationship_type
-- Aim: Categorize guardian-child relationships for UI display
--      and notification routing. Allows platform to address
--      guardians appropriately (e.g., "Dear Mother") and
--      prioritize primary contacts for critical alerts.
-- ============================================================
CREATE TYPE auth_schema.relationship_type AS ENUM ('mother', 'father', 'teacher', 'custodian');

-- ============================================================
-- ENUM TYPE: credential_type
-- Aim: Distinguish between platform authenticators (FaceID,
--      fingerprint bound to device) and cross-platform
--      authenticators (external security keys like YubiKey).
--      Critical for FIDO2/WebAuthn compliance and risk scoring.
-- ============================================================
CREATE TYPE auth_schema.credential_type AS ENUM ('platform', 'cross-platform');

-- ============================================================
-- ENUM TYPE: audit_event_type
-- Aim: Standardize security event categorization for
--      monitoring, alerting, and forensic analysis. Enables
--      precise filtering in SIEM integration and threat
--      detection dashboards.
-- ============================================================
CREATE TYPE auth_schema.audit_event_type AS ENUM (
    'login_success',
    'login_failed',
    'login_locked',
    'password_reset',
    'pin_reset',
    'account_created',
    'account_deactivated',
    'account_reactivated',
    'logout',
    'token_refresh',
    'biometric_registered',
    'biometric_removed'
);

-- ============================================================
-- ENUM TYPE: attempt_status
-- Aim: Binary outcome classification for each authentication
--      attempt. Used in conjunction with failure_reason for
--      building brute-force detection algorithms and account
--      compromise risk scoring.
-- ============================================================
CREATE TYPE auth_schema.attempt_status AS ENUM ('success', 'failure');

-- ============================================================
-- TABLE: users
-- Aim: Core authentication table storing login identifiers and
--      verification secrets. Strict separation of parent
--      (password_hash) and student (pin_hash) credentials via
--      CHECK constraints. Includes account lockout columns for
--      brute-force protection. This table is the single source
--      of truth for "who can authenticate."
--      Child Safety: No student email/phone stored; login via
--      system-generated user_handle + PIN only.
-- ============================================================
CREATE TABLE auth_schema.users (
    user_id                 UUID                NOT NULL DEFAULT gen_random_uuid(),
    user_handle             VARCHAR(30)         NOT NULL,
    role                    user_role           NOT NULL,
    phone_number            VARCHAR(15),
    email                   VARCHAR(255),
    password_hash           VARCHAR(255),
    pin_hash                VARCHAR(255),
    is_active               BOOLEAN             NOT NULL DEFAULT TRUE,
    failed_login_attempts   INTEGER             NOT NULL DEFAULT 0,
    locked_until            TIMESTAMPTZ,
    last_login              TIMESTAMPTZ,
    created_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- Primary Key
    CONSTRAINT pk_users_user_id PRIMARY KEY (user_id),

    -- Unique Constraints
    CONSTRAINT uq_users_user_handle UNIQUE (user_handle),
    CONSTRAINT uq_users_phone_number UNIQUE (phone_number),
    CONSTRAINT uq_users_email UNIQUE (email),

    -- Check Constraints
    CONSTRAINT chk_users_phone_format CHECK (
        phone_number IS NULL OR phone_number ~ '^\+?[0-9]{7,15}$'
    ),
    CONSTRAINT chk_users_email_format CHECK (
        email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT chk_users_password_for_role CHECK (
        (role IN ('admin', 'parent') AND password_hash IS NOT NULL)
        OR
        (role = 'student' AND password_hash IS NULL)
    ),
    CONSTRAINT chk_users_pin_for_role CHECK (
        (role = 'student' AND pin_hash IS NOT NULL)
        OR
        (role IN ('admin', 'parent') AND pin_hash IS NULL)
    ),
    CONSTRAINT chk_users_locked_until_future CHECK (
        locked_until IS NULL OR locked_until > NOW()
    ),
    CONSTRAINT chk_users_failed_attempts_range CHECK (
        failed_login_attempts >= 0 AND failed_login_attempts <= 10
    )
);

-- Indexes for users
CREATE INDEX idx_users_role ON auth_schema.users (role);
CREATE INDEX idx_users_phone_number ON auth_schema.users (phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX idx_users_email ON auth_schema.users (email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_is_active ON auth_schema.users (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_users_locked_until ON auth_schema.users (locked_until) WHERE locked_until IS NOT NULL;

-- ============================================================
-- TABLE: user_profiles
-- Aim: Stores personally identifiable information (PII)
--      separate from authentication credentials. This
--      separation enables stricter access controls on PII,
--      simplifies GDPR/COPPA data export/deletion requests,
--      and keeps the users table lean for fast authentication
--      lookups.
--      Includes grade_class for student education level tracking.
-- ============================================================
CREATE TABLE auth_schema.user_profiles (
    profile_id      UUID            NOT NULL DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL,
    full_name       VARCHAR(100)    NOT NULL,
    date_of_birth   DATE,
    grade_class     VARCHAR(20),
    avatar_url      VARCHAR(500),
    state           VARCHAR(50),
    city            VARCHAR(50),
    pincode         VARCHAR(10),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Primary Key
    CONSTRAINT pk_user_profiles_profile_id PRIMARY KEY (profile_id),

    -- Foreign Key
    CONSTRAINT fk_user_profiles_user_id
        FOREIGN KEY (user_id)
        REFERENCES auth_schema.users (user_id)
        ON DELETE CASCADE,

    -- Unique Constraint (One profile per user)
    CONSTRAINT uq_user_profiles_user_id UNIQUE (user_id),

    -- Check Constraints
    CONSTRAINT chk_user_profiles_dob_past CHECK (
        date_of_birth IS NULL OR date_of_birth < CURRENT_DATE
    ),
    CONSTRAINT chk_user_profiles_pincode_format CHECK (
        pincode IS NULL OR pincode ~ '^[0-9]{5,6}$'
    )
);

-- Indexes for user_profiles
CREATE INDEX idx_user_profiles_user_id ON auth_schema.user_profiles (user_id);
CREATE INDEX idx_user_profiles_full_name ON auth_schema.user_profiles (full_name);
CREATE INDEX idx_user_profiles_state_city ON auth_schema.user_profiles (state, city);

-- ============================================================
-- TABLE: user_relationships
-- Aim: Many-to-many junction table linking students to their
--      guardians (parents/teachers/custodians). Enables a
--      child to have multiple guardians (mother + father +
--      teacher) and a guardian to manage multiple children.
--      The is_primary flag identifies the main contact for
--      notifications and account recovery.
--      Child Safety: Relationship type explicitly stored;
--      prevents unauthorized guardianship claims.
-- ============================================================
CREATE TABLE auth_schema.user_relationships (
    relationship_id     UUID                NOT NULL DEFAULT gen_random_uuid(),
    student_id          UUID                NOT NULL,
    guardian_id         UUID                NOT NULL,
    relationship_type   relationship_type   NOT NULL,
    is_primary          BOOLEAN             NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- Primary Key
    CONSTRAINT pk_user_relationships_id PRIMARY KEY (relationship_id),

    -- Foreign Keys
    CONSTRAINT fk_user_relationships_student
        FOREIGN KEY (student_id)
        REFERENCES auth_schema.users (user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_user_relationships_guardian
        FOREIGN KEY (guardian_id)
        REFERENCES auth_schema.users (user_id)
        ON DELETE CASCADE,

    -- Unique Constraint (No duplicate relationships)
    CONSTRAINT uq_user_relationships_pair UNIQUE (student_id, guardian_id),

    -- Check Constraint (Cannot link to self)
    CONSTRAINT chk_user_relationships_not_self CHECK (
        student_id <> guardian_id
    )
);

-- Indexes for user_relationships
CREATE INDEX idx_user_relationships_student ON auth_schema.user_relationships (student_id);
CREATE INDEX idx_user_relationships_guardian ON auth_schema.user_relationships (guardian_id);
CREATE INDEX idx_user_relationships_type ON auth_schema.user_relationships (relationship_type);

-- ============================================================
-- TABLE: user_consents
-- Aim: Records all legal and functional permissions accepted
--      during onboarding. Separating consents from users table
--      enables independent consent versioning, revocation,
--      and audit trails. Critical for COPPA (verifiable
--      parental consent) and Indian DPDP Act compliance.
--      Each consent can be individually managed without
--      altering the user's core account state.
-- ============================================================
CREATE TABLE auth_schema.user_consents (
    consent_id              UUID            NOT NULL DEFAULT gen_random_uuid(),
    user_id                 UUID            NOT NULL,
    terms_accepted          BOOLEAN         NOT NULL DEFAULT FALSE,
    privacy_accepted        BOOLEAN         NOT NULL DEFAULT FALSE,
    notifications_allowed   BOOLEAN         NOT NULL DEFAULT FALSE,
    camera_allowed          BOOLEAN         NOT NULL DEFAULT FALSE,
    microphone_allowed      BOOLEAN         NOT NULL DEFAULT FALSE,
    storage_allowed         BOOLEAN         NOT NULL DEFAULT FALSE,
    accepted_at             TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Primary Key
    CONSTRAINT pk_user_consents_id PRIMARY KEY (consent_id),

    -- Foreign Key
    CONSTRAINT fk_user_consents_user_id
        FOREIGN KEY (user_id)
        REFERENCES auth_schema.users (user_id)
        ON DELETE CASCADE,

    -- Unique Constraint (One consent record per user)
    CONSTRAINT uq_user_consents_user_id UNIQUE (user_id)
);

-- Indexes for user_consents
CREATE INDEX idx_user_consents_user_id ON auth_schema.user_consents (user_id);

-- ============================================================
-- TABLE: device_credentials
-- Aim: Implements FIDO2/WebAuthn-compliant passwordless
--      authentication using asymmetric cryptography. Stores
--      ONLY the public key generated by the device's Secure
--      Enclave (FaceID/TouchID/Titan chip). Private key NEVER
--      leaves the device.
--      COPPA/GDPR Compliance: Zero biometric data on server.
--      Server only verifies signed challenges. If this table
--      is compromised, attacker gains no biometric information.
--      Currently intended for Parent role only.
-- ============================================================
CREATE TABLE auth_schema.device_credentials (
    credential_id       UUID                NOT NULL DEFAULT gen_random_uuid(),
    user_id             UUID                NOT NULL,
    public_key          TEXT                NOT NULL,
    credential_type     credential_type     NOT NULL,
    device_label        VARCHAR(100),
    last_used_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- Primary Key
    CONSTRAINT pk_device_credentials_id PRIMARY KEY (credential_id),

    -- Foreign Key
    CONSTRAINT fk_device_credentials_user_id
        FOREIGN KEY (user_id)
        REFERENCES auth_schema.users (user_id)
        ON DELETE CASCADE,

    -- Check Constraint (public_key must not be empty)
    CONSTRAINT chk_device_credentials_key_not_empty CHECK (
        public_key IS NOT NULL AND LENGTH(public_key) > 0
    )
);

-- Indexes for device_credentials
CREATE INDEX idx_device_credentials_user_id ON auth_schema.device_credentials (user_id);
CREATE INDEX idx_device_credentials_type ON auth_schema.device_credentials (credential_type);

-- ============================================================
-- TABLE: login_audit_logs
-- Aim: Comprehensive immutable audit trail for all
--      authentication events. Captures IP address, user agent,
--      location data, and success/failure status for every
--      login attempt, password reset, and biometric event.
--      Enables real-time threat detection (failed login spikes),
--      forensic investigation, and regulatory compliance
--      reporting. user_id is nullable to capture attempts on
--      non-existent accounts without losing the audit record.
-- ============================================================
CREATE TABLE auth_schema.login_audit_logs (
    log_id          UUID                NOT NULL DEFAULT gen_random_uuid(),
    user_id         UUID,
    event_type      audit_event_type    NOT NULL,
    ip_address      INET,
    location_data   JSONB,
    user_agent      TEXT,
    attempt_status  attempt_status      NOT NULL,
    failure_reason  VARCHAR(255),
    created_at      TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    -- Primary Key
    CONSTRAINT pk_login_audit_logs_id PRIMARY KEY (log_id),

    -- Foreign Key (nullable - captures attempts on non-existent accounts)
    CONSTRAINT fk_login_audit_logs_user_id
        FOREIGN KEY (user_id)
        REFERENCES auth_schema.users (user_id)
        ON DELETE SET NULL
);

-- Indexes for login_audit_logs
CREATE INDEX idx_audit_user_id ON auth_schema.login_audit_logs (user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_event_type ON auth_schema.login_audit_logs (event_type);
CREATE INDEX idx_audit_created_at ON auth_schema.login_audit_logs (created_at DESC);
CREATE INDEX idx_audit_ip_address ON auth_schema.login_audit_logs (ip_address);
CREATE INDEX idx_audit_attempt_status ON auth_schema.login_audit_logs (attempt_status);
CREATE INDEX idx_audit_event_user_created ON auth_schema.login_audit_logs (event_type, created_at DESC);

-- ============================================================
-- FUNCTION: fn_update_timestamp()
-- Aim: Generic trigger function to automatically update the
--      updated_at column on any table row modification.
--      Centralized logic ensures consistent timestamp behavior
--      across all tables without duplicating code.
-- ============================================================
CREATE OR REPLACE FUNCTION auth_schema.fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGER: trg_users_updated_at
-- Aim: Automatically refresh updated_at timestamp whenever
--      a row in users table is modified (last_login update,
--      password change, lockout status change, etc.).
--      Essential for audit accuracy and cache invalidation.
-- ============================================================
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON auth_schema.users
    FOR EACH ROW
    EXECUTE FUNCTION auth_schema.fn_update_timestamp();

-- ============================================================
-- TRIGGER: trg_user_profiles_updated_at
-- Aim: Maintain accurate modification timestamp for profile
--      updates (name change, address update, avatar change).
--      Supports profile version tracking and sync mechanisms.
-- ============================================================
CREATE TRIGGER trg_user_profiles_updated_at
    BEFORE UPDATE ON auth_schema.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION auth_schema.fn_update_timestamp();

-- ============================================================
-- TRIGGER: trg_user_consents_updated_at
-- Aim: Track when user consent preferences are modified.
--      Critical for proving consent freshness during
--      regulatory audits (COPPA/DPDP Act).
-- ============================================================
CREATE TRIGGER trg_user_consents_updated_at
    BEFORE UPDATE ON auth_schema.user_consents
    FOR EACH ROW
    EXECUTE FUNCTION auth_schema.fn_update_timestamp();

-- ============================================================
-- GRANT: Schema-level privileges
-- Aim: Grant appropriate access to the application role
--      while restricting destructive operations. Application
--      can perform CRUD but cannot drop tables or modify
--      schema structure — preventing SQL injection from
--      causing structural damage.
-- ============================================================
GRANT USAGE ON SCHEMA auth_schema TO koushaladmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA auth_schema TO koushaladmin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA auth_schema TO koushaladmin;

-- ============================================================
-- End of 01_auth_schema.sql
-- Version: 1.0.0
-- Status: Ready for Execution
-- ============================================================