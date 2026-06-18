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
 * Version 1.1.0 | Upgraded OTP HTML template to Ocean Blue 6-digit array-style boxes with no-reply sender
 * Version 1.2.0 | Added sendCredentialsEmail — sends child handle + PIN to parent after successful registration
 * Version 1.2.1 | FIX: Added SMTP connection pooling (pool:true, maxConnections:3) to prevent ECONNRESET, added retry logic
 * Version 1.3.0 | FEAT: Added sendForgotPasswordOtpEmail — branded forgot password OTP template with security warning
 *
 * Aim: Email Transporter Configuration
 * Why: Creates a reusable Nodemailer transporter using Gmail SMTP with
 *      connection pooling. Sends branded OTP, credentials, and forgot
 *      password emails. Retries once on connection failure.
 *      Sender uses no-reply@koshiv.com branding.
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
  pool: true,
  maxConnections: 3,
  maxMessages: Infinity,
  connectionTimeout: 10000,
  greetingTimeout: 10000,
  socketTimeout: 15000,
});

transporter.verify((error) => {
  if (error) {
    logger.error({ err: error }, 'SMTP transporter verification failed');
  } else {
    logger.info('SMTP transporter ready to send emails (pooled, max 3 connections)');
  }
});

const generateOtpHtml = (otp: string): string => {
  const otpDigits = String(otp).split('');
  const otpBoxesHtml = otpDigits
    .map((digit) => {
      return `<span style="display: inline-block; width: 34px; height: 46px; line-height: 46px; margin: 0 5px; background-color: #f0f4f8; border: 1px solid #cce0ef; border-radius: 4px; font-size: 26px; font-weight: bold; color: #005B8F; text-align: center;">${digit}</span>`;
    })
    .join('');

  return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>koshiv - OTP Verification</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f9f9f9;">
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f9f9f9; padding: 40px 0;">
        <tr>
            <td align="center">
                <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="600" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); border: 1px solid #e0e0e0;">
                    <tr>
                        <td style="border-top: 6px solid #005B8F; padding: 30px 40px; text-align: center; background-color: #ffffff; border-bottom: 1px solid #eeeeee;">
                            <h1 style="margin: 0; font-size: 22px; color: #005B8F; letter-spacing: 1px; text-transform: uppercase;">koshiv</h1>
                            <p style="margin: 6px 0 0; font-size: 13px; color: #666666;">Learning App for Kids</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 20px 0; font-size: 16px; color: #333333; line-height: 1.5;">Dear Parent,</p>
                            <p style="margin: 0 0 30px 0; font-size: 16px; color: #333333; line-height: 1.5;">Your One-Time Password (OTP) for verification is provided below. Please enter this code to complete your authentication.</p>
                            <div style="text-align: center; margin: 30px 0;">${otpBoxesHtml}</div>
                            <p style="margin: 30px 0 0 0; font-size: 14px; color: #666666; text-align: center;">This OTP is valid for <strong>5 minutes</strong>. Do not share this code with anyone.</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="background-color: #f4f7f6; padding: 25px 40px; border-top: 1px solid #eeeeee;">
                            <p style="margin: 0; font-size: 12px; color: #888888; text-align: justify; line-height: 1.6;">
                                <strong>Security Notice:</strong> If you did not initiate this request for koshiv, please completely disregard this email. Your account remains secure, and no further action is required. Do not forward this email.
                            </p>
                            <p style="margin: 12px 0 0; font-size: 11px; color: #aaaaaa; text-align: center;">
                                This is an automated message from <strong>no-reply@koshiv.com</strong>. Please do not reply.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>`;
};

const sendWithRetry = async (mailOptions: any, label: string): Promise<boolean> => {
  try {
    const info = await transporter.sendMail(mailOptions);
    logger.info({ to: mailOptions.to, messageId: info.messageId }, `${label} email sent successfully`);
    return true;
  } catch (error) {
    const errCode = (error as any).code;
    logger.warn({ err: error, to: mailOptions.to, code: errCode }, `First ${label} email attempt failed — retrying once`);
    try {
      await new Promise((resolve) => setTimeout(resolve, 500));
      const info = await transporter.sendMail(mailOptions);
      logger.info({ to: mailOptions.to, messageId: info.messageId }, `${label} email sent successfully on retry`);
      return true;
    } catch (retryError) {
      logger.error({ err: retryError, to: mailOptions.to }, `Failed to send ${label} email after retry`);
      return false;
    }
  }
};

export const sendOtpEmail = async (to: string, otp: string): Promise<boolean> => {
  const htmlContent = generateOtpHtml(otp);
  return sendWithRetry({
    from: `"koshiv Accounts" <${process.env.EMAIL_FROM}>`,
    to,
    subject: 'Your OTP for koshiv Verification',
    text: `Your OTP is: ${otp}. It expires in 5 minutes. Do not share this code with anyone.`,
    html: htmlContent,
  }, 'OTP');
};

export interface CredentialsEmailData {
  parent_name: string;
  parent_handle: string;
  child_name: string;
  child_handle: string;
  child_pin: string;
}

export const sendCredentialsEmail = async (to: string, data: CredentialsEmailData): Promise<boolean> => {
  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>koshiv - Registration Successful</title></head>
<body style="margin: 0; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f9f9f9;">
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f9f9f9; padding: 40px 0;">
        <tr><td align="center">
            <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="600" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); border: 1px solid #e0e0e0;">
                <tr><td style="border-top: 6px solid #005B8F; padding: 30px 40px; text-align: center; background-color: #ffffff; border-bottom: 1px solid #eeeeee;">
                    <h1 style="margin: 0; font-size: 22px; color: #005B8F; letter-spacing: 1px; text-transform: uppercase;">koshiv</h1>
                    <p style="margin: 6px 0 0; font-size: 13px; color: #666666;">Learning App for Kids</p>
                </td></tr>
                <tr><td style="padding: 40px;">
                    <p style="margin: 0 0 16px 0; font-size: 16px; color: #333333; line-height: 1.5;">Dear ${data.parent_name},</p>
                    <p style="margin: 0 0 24px 0; font-size: 16px; color: #333333; line-height: 1.5;">Your account has been created successfully! Below are the login credentials for your child, <strong>${data.child_name}</strong>.</p>
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; margin: 24px 0;">
                        <tr><td style="padding: 24px;">
                            <p style="margin: 0 0 6px; font-size: 12px; color: #64748b; text-transform: uppercase; letter-spacing: 1px;">Child Login Handle</p>
                            <p style="margin: 0 0 20px; font-size: 18px; font-weight: bold; color: #005B8F; font-family: 'Courier New', monospace;">${data.child_handle}</p>
                            <p style="margin: 0 0 6px; font-size: 12px; color: #64748b; text-transform: uppercase; letter-spacing: 1px;">Child Login PIN</p>
                            <p style="margin: 0; font-size: 24px; font-weight: bold; color: #005B8F; font-family: 'Courier New', monospace; letter-spacing: 6px;">${data.child_pin}</p>
                        </td></tr>
                    </table>
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 20px 0;">
                        <tr><td style="background-color: #fef2f2; border-left: 4px solid #ef4444; border-radius: 8px; padding: 14px 18px;">
                            <p style="margin: 0; color: #991b1b; font-size: 13px; line-height: 1.5;"><strong>Important:</strong> Save these credentials safely. Your child will need the Handle and PIN to log in. Do not share the PIN with anyone else.</p>
                        </td></tr>
                    </table>
                    <p style="margin: 16px 0 0; font-size: 13px; color: #666666;">Your Parent Handle: <strong>${data.parent_handle}</strong></p>
                </td></tr>
                <tr><td style="background-color: #f4f7f6; padding: 25px 40px; border-top: 1px solid #eeeeee;">
                    <p style="margin: 0; font-size: 12px; color: #888888; text-align: justify; line-height: 1.6;"><strong>Security Notice:</strong> koshiv will never ask for your child's PIN via email or phone.</p>
                    <p style="margin: 12px 0 0; font-size: 11px; color: #aaaaaa; text-align: center;">This is an automated message from <strong>no-reply@koshiv.com</strong>. Please do not reply.</p>
                </td></tr>
            </table>
        </td></tr>
    </table>
</body>
</html>`;

  return sendWithRetry({
    from: `"koshiv Accounts" <${process.env.EMAIL_FROM}>`,
    to,
    subject: `Welcome to koshiv - Child Login Credentials for ${data.child_name}`,
    text: `Hello ${data.parent_name},\n\nYour child ${data.child_name}'s login credentials:\n\nHandle: ${data.child_handle}\nPIN: ${data.child_pin}\n\nYour Parent Handle: ${data.parent_handle}\n\nPlease save these credentials safely.`,
    html,
  }, 'Credentials');
};

/**
 * Send forgot password OTP email.
 * v1.3.0 — Branded template with password reset security warning.
 */
export const sendForgotPasswordOtpEmail = async (to: string, otp: string): Promise<boolean> => {
  const otpDigits = String(otp).split('');
  const otpBoxesHtml = otpDigits
    .map((digit) => {
      return `<span style="display: inline-block; width: 34px; height: 46px; line-height: 46px; margin: 0 5px; background-color: #f0f4f8; border: 1px solid #cce0ef; border-radius: 4px; font-size: 26px; font-weight: bold; color: #005B8F; text-align: center;">${digit}</span>`;
    })
    .join('');

  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>koshiv - Password Reset OTP</title></head>
<body style="margin: 0; padding: 0; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f9f9f9;">
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f9f9f9; padding: 40px 0;">
        <tr><td align="center">
            <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="600" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); border: 1px solid #e0e0e0;">
                <tr><td style="border-top: 6px solid #f59e0b; padding: 30px 40px; text-align: center; background-color: #ffffff; border-bottom: 1px solid #eeeeee;">
                    <h1 style="margin: 0; font-size: 22px; color: #005B8F; letter-spacing: 1px; text-transform: uppercase;">koshiv</h1>
                    <p style="margin: 6px 0 0; font-size: 13px; color: #666666;">Learning App for Kids</p>
                </td></tr>
                <tr><td style="padding: 40px;">
                    <p style="margin: 0 0 16px 0; font-size: 16px; color: #333333; line-height: 1.5;">Dear Parent,</p>
                    <p style="margin: 0 0 24px 0; font-size: 16px; color: #333333; line-height: 1.5;">We received a request to reset your password. Use the OTP below to verify your identity.</p>
                    <div style="text-align: center; margin: 30px 0;">${otpBoxesHtml}</div>
                    <p style="margin: 30px 0 0 0; font-size: 14px; color: #666666; text-align: center;">This OTP is valid for <strong>5 minutes</strong>. Do not share this code with anyone.</p>
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 24px 0;">
                        <tr><td style="background-color: #fef2f2; border-left: 4px solid #ef4444; border-radius: 8px; padding: 14px 18px;">
                            <p style="margin: 0; color: #991b1b; font-size: 13px; line-height: 1.5;"><strong>Warning:</strong> If you did not request a password reset, please ignore this email. Your account remains secure. Do not share this OTP with anyone, including koshiv staff.</p>
                        </td></tr>
                    </table>
                </td></tr>
                <tr><td style="background-color: #f4f7f6; padding: 25px 40px; border-top: 1px solid #eeeeee;">
                    <p style="margin: 0; font-size: 12px; color: #888888; text-align: justify; line-height: 1.6;"><strong>Security Notice:</strong> koshiv will never ask for your OTP or password via email or phone. If you suspect any unauthorized access, please contact support immediately.</p>
                    <p style="margin: 12px 0 0; font-size: 11px; color: #aaaaaa; text-align: center;">This is an automated message from <strong>no-reply@koshiv.com</strong>. Please do not reply.</p>
                </td></tr>
            </table>
        </td></tr>
    </table>
</body>
</html>`;

  return sendWithRetry({
    from: `"koshiv Accounts" <${process.env.EMAIL_FROM}>`,
    to,
    subject: 'Password Reset OTP - koshiv',
    text: `Your password reset OTP is: ${otp}. It expires in 5 minutes. If you did not request this, please ignore this email.`,
    html,
  }, 'Forgot Password OTP');
};

export default transporter;