/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/controllers/otp.controller.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial OTP controller — handles send OTP and verify OTP HTTP requests
 * Version 1.1.0 | Integrated Nodemailer — sends real OTP email, removed raw OTP from response
 *
 * Aim: OTP HTTP Request/Response Handler
 * Why: Receives HTTP requests from routes, validates input, calls OTP
 *      service functions, sends OTP via email using Nodemailer.
 *      No business logic — delegates entirely to otp.service.ts.
 * ============================================================
 */

import { Request, Response } from 'express';
import pino from 'pino';
import { generateOtp, storeOtp, validateOtp, otpExists } from '../services/otp.service';
import { sendOtpEmail } from '../config/mailer';

const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:yyyy-mm-dd HH:MM:ss',
      ignore: 'pid,hostname',
    },
  },
  level: process.env.LOG_LEVEL || 'debug',
});

/**
 * POST /api/v1/auth/otp/send
 * Body: { email: string }
 * Generates OTP, stores in Redis, sends via email, returns success.
 */
export const sendOtp = async (req: Request, res: Response): Promise<void> => {
  const { email } = req.body;

  if (!email || typeof email !== 'string') {
    logger.warn('OTP send request missing email');
    res.status(400).json({ error: 'Email is required' });
    return;
  }

  try {
    const exists = await otpExists(email);
    if (exists) {
      logger.warn({ email }, 'OTP already active — request rejected');
      res.status(429).json({ error: 'OTP already sent. Please wait before requesting again.' });
      return;
    }

    const { rawOtp, hashedOtp } = generateOtp();
    await storeOtp(email, hashedOtp);

    logger.info({ email }, 'OTP generated and stored — sending email');

    const emailSent = await sendOtpEmail(email, rawOtp);

    if (!emailSent) {
      logger.error({ email }, 'OTP email failed to send');
      res.status(500).json({ error: 'Failed to send OTP email. Please try again.' });
      return;
    }

    logger.info({ email }, 'OTP sent successfully via email');
    res.status(200).json({
      message: 'OTP sent successfully to your email',
    });
  } catch (error) {
    logger.error({ err: error, email }, 'Failed to send OTP');
    res.status(500).json({ error: 'Failed to send OTP' });
  }
};

/**
 * POST /api/v1/auth/otp/verify
 * Body: { email: string, otp: string }
 * Validates OTP against Redis, returns JWT tokens on success.
 */
export const verifyOtp = async (req: Request, res: Response): Promise<void> => {
  const { email, otp } = req.body;

  if (!email || !otp || typeof email !== 'string' || typeof otp !== 'string') {
    logger.warn('OTP verify request missing email or otp');
    res.status(400).json({ error: 'Email and OTP are required' });
    return;
  }

  try {
    const isValid = await validateOtp(email, otp);

    if (!isValid) {
      logger.warn({ email }, 'OTP verification failed');
      res.status(401).json({ error: 'Invalid or expired OTP' });
      return;
    }

    logger.info({ email }, 'OTP verified successfully');
    res.status(200).json({
      message: 'OTP verified successfully',
      verified: true,
    });
  } catch (error) {
    logger.error({ err: error, email }, 'Failed to verify OTP');
    res.status(500).json({ error: 'Failed to verify OTP' });
  }
};