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
 *
 * Aim: Email Transporter Configuration
 * Why: Creates a reusable Nodemailer transporter using Gmail SMTP.
 *      Used by OTP service to send branded OTP emails to parents.
 *      Features Ocean Blue professional template with individual
 *      6-digit OTP boxes and security notice in footer.
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
});

transporter.verify((error) => {
  if (error) {
    logger.error({ err: error }, 'SMTP transporter verification failed');
  } else {
    logger.info('SMTP transporter ready to send emails');
  }
});

/**
 * Generate Ocean Blue styled HTML template for OTP email.
 * Renders 6 individual square boxes for each digit.
 */
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
                    
                    <!-- Header with Ocean Blue Border -->
                    <tr>
                        <td style="border-top: 6px solid #005B8F; padding: 30px 40px; text-align: center; background-color: #ffffff; border-bottom: 1px solid #eeeeee;">
                            <h1 style="margin: 0; font-size: 22px; color: #005B8F; letter-spacing: 1px; text-transform: uppercase;">koshiv</h1>
                            <p style="margin: 6px 0 0; font-size: 13px; color: #666666;">Learning App for Kids</p>
                        </td>
                    </tr>
                    
                    <!-- Body Content -->
                    <tr>
                        <td style="padding: 40px;">
                            <p style="margin: 0 0 20px 0; font-size: 16px; color: #333333; line-height: 1.5;">Dear Parent,</p>
                            <p style="margin: 0 0 30px 0; font-size: 16px; color: #333333; line-height: 1.5;">Your One-Time Password (OTP) for verification is provided below. Please enter this code to complete your authentication.</p>
                            
                            <!-- Array-Style 6-Digit OTP Boxes -->
                            <div style="text-align: center; margin: 30px 0;">
                                ${otpBoxesHtml}
                            </div>
                            
                            <p style="margin: 30px 0 0 0; font-size: 14px; color: #666666; text-align: center;">This OTP is valid for <strong>5 minutes</strong>. Do not share this code with anyone.</p>
                        </td>
                    </tr>
                    
                    <!-- Footer & Security Declaration -->
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

export const sendOtpEmail = async (to: string, otp: string): Promise<boolean> => {
  try {
    const htmlContent = generateOtpHtml(otp);

    const info = await transporter.sendMail({
      from: `"koshiv Accounts" <${process.env.EMAIL_FROM}>`,
      to,
      subject: 'Your OTP for koshiv Verification',
      text: `Your OTP is: ${otp}. It expires in 5 minutes. Do not share this code with anyone.`,
      html: htmlContent,
    });

    logger.info({ to, messageId: info.messageId }, 'OTP email sent successfully');
    return true;
  } catch (error) {
    logger.error({ err: error, to }, 'Failed to send OTP email');
    return false;
  }
};

export default transporter;