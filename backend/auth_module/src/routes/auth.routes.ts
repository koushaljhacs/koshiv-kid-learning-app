/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/routes/auth.routes.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Auth routes — OTP, parent registration, child login, token refresh endpoints
 * Version 1.1.0 | Added parent login route (email+password) integrated with auth.service.ts
 *
 * Aim: Auth Module API Route Definitions
 * Why: Maps HTTP endpoints to controller functions.
 *      All routes prefixed with /api/v1/auth/.
 *      No business logic — delegates to controllers.
 * ============================================================
 */

import { Router } from 'express';
import { sendOtp, verifyOtp } from '../controllers/otp.controller';
import {
  getRegistrationOptions,
  verifyRegistration,
  childLogin,
  refreshToken,
  parentLoginHandler,
} from '../controllers/auth.controller';

const router = Router();

// Parent Login (Email + Password)
router.post('/parent/login', parentLoginHandler);

// OTP Routes
router.post('/otp/send', sendOtp);
router.post('/otp/verify', verifyOtp);

// Parent Registration (FIDO2/WebAuthn)
router.post('/parent/register/options', getRegistrationOptions);
router.post('/parent/register/verify', verifyRegistration);

// Student Login (Handle + PIN)
router.post('/student/login', childLogin);

// Token Management
router.post('/token/refresh', refreshToken);

export default router;