/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/config/mailer.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Nodemailer transporter — Gmail SMTP relay
 *
 * Aim: Email Transporter Configuration
 * Why: Creates a reusable Nodemailer transporter using Gmail SMTP.
 *      Used by OTP service to send OTP emails to parents.
 *      Credentials loaded from .env (never committed).
 * ============================================================
 */

import nodemailer from 'nodemailer';
import dotenv from 'dotenv';
import pino from 'pino';

dotenv.config();

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

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587', 10),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

transporter.verify((error) => {
  if (error) {
    logger.error({ err: error }, 'SMTP transporter verification failed');
  } else {
    logger.info('SMTP transporter ready to send emails');
  }
});

export const sendOtpEmail = async (to: string, otp: string): Promise<boolean> => {
  try {
    const info = await transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to,
      subject: 'Your OTP for koshiv Login',
      text: `Your OTP is: ${otp}. It expires in 5 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>koshiv - Learning App for Kids</h2>
          <p>Your One-Time Password (OTP) is:</p>
          <h1 style="font-size: 36px; letter-spacing: 5px; color: #4CAF50;">${otp}</h1>
          <p>This OTP expires in <strong>5 minutes</strong>.</p>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      `,
    });

    logger.info({ to, messageId: info.messageId }, 'OTP email sent successfully');
    return true;
  } catch (error) {
    logger.error({ err: error, to }, 'Failed to send OTP email');
    return false;
  }
};

export default transporter;