/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/server.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Express server — port 34554, DB + Redis health check, Pino logger
 * Version 1.1.0 | Integrated auth routes, added middleware debugging, startup logging, request logging
 * Version 1.2.0 | Bound server to 0.0.0.0 for Tailscale network access, added SMTP env vars debug logging
 * Version 1.3.0 | ADVANCED MONITORING: Added correlation ID per request, request/response timing (ms), sensitive field masking (password/pin/token), complete error stack traces, auto-detect modified files on restart
 *
 * Aim: Auth Module Express Server Entry Point — ADVANCED DEBUG MODE
 * Why: Initializes Express app on port 34554 bound to all interfaces (0.0.0.0).
 *      Every request gets a unique correlation ID for tracing.
 *      Logs REQUEST (masked body) and RESPONSE (status, timing, truncated body).
 *      All credentials (password, pin, token) masked as "***REDACTED***".
 *      Tracks response time in ms. Full error stack for 5xx.
 *      Fails fast (process.exit(1)) if infrastructure connection fails.
 * ============================================================
 */

import express, { Application, Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import dotenv from 'dotenv';
import pino from 'pino';
import { connectDb } from './config/db';
import { connectRedis } from './config/redis';
import authRoutes from './routes/auth.routes';

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

const app: Application = express();
const PORT = parseInt(process.env.APP_PORT || '34554', 10);

// ============================================================
// GLOBAL MIDDLEWARES
// ============================================================

// Parse JSON request body
app.use(express.json());
logger.debug('JSON body parser middleware enabled');

// ============================================================
// REQUEST LOGGING MIDDLEWARE (ADVANCED)
// ============================================================

/**
 * Fields that should be masked in logs.
 * Never log passwords, PINs, or tokens in plain text.
 */
const SENSITIVE_FIELDS = ['password', 'pin', 'otp', 'token', 'accessToken', 'refreshToken', 'authorization'];

/**
 * Extend Express Request to store correlation ID and start time.
 */
declare global {
  namespace Express {
    interface Request {
      correlationId?: string;
      startTime?: number;
    }
  }
}

/**
 * Mask sensitive fields in an object.
 * Replaces values with "***REDACTED***" for any key matching SENSITIVE_FIELDS.
 */
const maskSensitiveData = (body: any): any => {
  if (!body || typeof body !== 'object') return body;

  if (Array.isArray(body)) {
    return body.map(maskSensitiveData);
  }

  const masked: any = {};
  for (const [key, value] of Object.entries(body)) {
    const lowerKey = key.toLowerCase();
    if (SENSITIVE_FIELDS.some((field) => lowerKey.includes(field))) {
      masked[key] = '***REDACTED***';
    } else if (typeof value === 'object' && value !== null) {
      masked[key] = maskSensitiveData(value);
    } else {
      masked[key] = value;
    }
  }
  return masked;
};

/**
 * Truncate string to maxLength for logging.
 */
const truncate = (str: string, maxLength: number = 300): string => {
  if (!str || str.length <= maxLength) return str;
  return str.substring(0, maxLength) + `... [TRUNCATED, total ${str.length} chars]`;
};

/**
 * Middleware: Log every incoming request with correlation ID.
 * Attaches correlationId and startTime to request object.
 */
app.use((req: Request, res: Response, next: NextFunction) => {
  // Generate unique correlation ID
  req.correlationId = crypto.randomBytes(4).toString('hex');
  req.startTime = Date.now();

  const maskedBody = req.body && Object.keys(req.body).length > 0
    ? maskSensitiveData(req.body)
    : undefined;

  logger.info(
    {
      correlationId: req.correlationId,
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      userAgent: req.get('User-Agent') || 'unknown',
      contentType: req.get('Content-Type') || 'unknown',
      body: maskedBody,
    },
    `REQ | ${req.correlationId} | ${req.method} ${req.originalUrl}`,
  );

  next();
});

// ============================================================
// RESPONSE LOGGING MIDDLEWARE (ADVANCED)
// ============================================================

/**
 * Middleware: Log response after it's sent.
 * Captures status code, response time, and truncated response body.
 */
app.use((req: Request, res: Response, next: NextFunction) => {
  // Store original json function
  const originalJson = res.json.bind(res);

  // Override json to capture response body
  res.json = function (body: any) {
    const responseTime = req.startTime ? Date.now() - req.startTime : 0;
    const statusCode = res.statusCode;

    // Mask sensitive data in response
    const maskedBody = maskSensitiveData(body);
    const bodyStr = typeof maskedBody === 'object'
      ? JSON.stringify(maskedBody)
      : String(maskedBody);

    const logData = {
      correlationId: req.correlationId,
      statusCode,
      responseTimeMs: responseTime,
      body: truncate(bodyStr),
    };

    if (statusCode >= 500) {
      logger.error(logData, `RES | ${req.correlationId} | ${statusCode} | ${responseTime}ms | ERROR`);
    } else if (statusCode >= 400) {
      logger.warn(logData, `RES | ${req.correlationId} | ${statusCode} | ${responseTime}ms | CLIENT ERROR`);
    } else {
      logger.info(logData, `RES | ${req.correlationId} | ${statusCode} | ${responseTime}ms`);
    }

    return originalJson(body);
  };

  next();
});

// ============================================================
// ROUTES
// ============================================================

// Health check endpoint
app.get('/health', async (_req: Request, res: Response): Promise<void> => {
  logger.debug({ correlationId: _req.correlationId }, 'Health check requested');

  const dbOk = await connectDb();
  const redisOk = await connectRedis();

  const healthData = {
    service: 'koshiv-auth-module',
    status: dbOk && redisOk ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    checks: {
      database: dbOk ? 'connected' : 'disconnected',
      redis: redisOk ? 'connected' : 'disconnected',
    },
  };

  if (dbOk && redisOk) {
    logger.info({ correlationId: _req.correlationId, ...healthData }, 'Health check passed');
    res.status(200).json(healthData);
  } else {
    logger.warn({ correlationId: _req.correlationId, ...healthData }, 'Health check degraded');
    res.status(503).json(healthData);
  }
});

// Auth routes
app.use('/api/v1/auth', authRoutes);
logger.debug('Auth routes mounted at /api/v1/auth');

// ============================================================
// ERROR HANDLING
// ============================================================

// 404 handler — catch unmatched routes
app.use((req: Request, res: Response) => {
  const responseTime = req.startTime ? Date.now() - req.startTime : 0;

  logger.warn(
    {
      correlationId: req.correlationId,
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      responseTimeMs: responseTime,
    },
    `404 | ${req.correlationId} | Route not found: ${req.method} ${req.originalUrl}`,
  );

  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl,
    method: req.method,
    correlationId: req.correlationId,
  });
});

// Global error handler
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  const responseTime = req.startTime ? Date.now() - req.startTime : 0;

  logger.error(
    {
      correlationId: req.correlationId,
      error: {
        name: err.name,
        message: err.message,
        stack: err.stack,
      },
      method: req.method,
      url: req.originalUrl,
      maskedBody: req.body ? maskSensitiveData(req.body) : undefined,
      responseTimeMs: responseTime,
    },
    `ERROR | ${req.correlationId} | 500 | ${err.message}`,
  );

  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    correlationId: req.correlationId,
  });
});

// ============================================================
// STARTUP
// ============================================================

app.listen(PORT, '0.0.0.0', async (): Promise<void> => {
  logger.info('============================================================');
  logger.info({ port: PORT, bind: '0.0.0.0' }, 'Auth Module server starting');
  logger.info('============================================================');

  logger.debug('Step 1/4: Loading environment variables...');
  logger.debug(
    {
      DB_HOST: process.env.DB_HOST || 'NOT SET',
      DB_PORT: process.env.DB_PORT || 'NOT SET',
      DB_NAME: process.env.DB_NAME || 'NOT SET',
      DB_USER: process.env.DB_USER || 'NOT SET',
      DB_PASSWORD: process.env.DB_PASSWORD ? '***HIDDEN***' : 'NOT SET',
      REDIS_HOST: process.env.REDIS_HOST || 'NOT SET',
      REDIS_PORT: process.env.REDIS_PORT || 'NOT SET',
      REDIS_PASSWORD: process.env.REDIS_PASSWORD ? '***HIDDEN***' : 'NOT SET',
      SMTP_HOST: process.env.SMTP_HOST || 'NOT SET',
      SMTP_PORT: process.env.SMTP_PORT || 'NOT SET',
      SMTP_USER: process.env.SMTP_USER || 'NOT SET',
      SMTP_PASS: process.env.SMTP_PASS ? '***HIDDEN***' : 'NOT SET',
      APP_PORT: process.env.APP_PORT || 'NOT SET',
      RP_ID: process.env.RP_ID || 'NOT SET',
      NODE_ENV: process.env.NODE_ENV || 'development',
      LOG_LEVEL: process.env.LOG_LEVEL || 'debug',
    },
    'Environment variables loaded',
  );

  logger.debug('Step 2/4: Verifying database connection...');
  const dbOk = await connectDb();

  if (dbOk) {
    logger.info({ host: process.env.DB_HOST, port: process.env.DB_PORT, database: process.env.DB_NAME }, 'PostgreSQL connected successfully');
  } else {
    logger.fatal({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
    }, 'PostgreSQL connection FAILED');
  }

  logger.debug('Step 3/4: Verifying Redis connection...');
  const redisOk = await connectRedis();

  if (redisOk) {
    logger.info({ host: process.env.REDIS_HOST, port: process.env.REDIS_PORT }, 'Redis connected successfully');
  } else {
    logger.fatal({
      host: process.env.REDIS_HOST,
      port: process.env.REDIS_PORT,
    }, 'Redis connection FAILED');
  }

  logger.debug('Step 4/4: Checking loaded routes...');
  logger.info(
    {
      routes: [
        'GET  /health',
        'POST /api/v1/auth/register/init',
        'POST /api/v1/auth/register/complete',
        'POST /api/v1/auth/parent/login',
        'POST /api/v1/auth/otp/send',
        'POST /api/v1/auth/otp/verify',
        'POST /api/v1/auth/parent/register/options',
        'POST /api/v1/auth/parent/register/verify',
        'POST /api/v1/auth/student/login',
        'POST /api/v1/auth/token/refresh',
      ],
    },
    'Available API endpoints',
  );

  if (dbOk && redisOk) {
    logger.info('============================================================');
    logger.info('Auth Service Database and Cache connected successfully');
    logger.info({ port: PORT, bind: '0.0.0.0', env: process.env.NODE_ENV || 'development' }, 'Auth Module is ready to accept requests');
    logger.info('============================================================');
  } else {
    logger.fatal('============================================================');
    logger.fatal('Infrastructure connection failed. Server cannot start.');
    logger.fatal('============================================================');

    if (!dbOk) {
      logger.fatal('[ACTION REQUIRED] PostgreSQL connection failed. Check:');
      logger.fatal('  1. Is PostgreSQL Docker container running?');
      logger.fatal('  2. Is Tailscale connected?');
      logger.fatal('  3. Are DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME correct in .env?');
    }

    if (!redisOk) {
      logger.fatal('[ACTION REQUIRED] Redis connection failed. Check:');
      logger.fatal('  1. Is Redis Docker container running?');
      logger.fatal('  2. Is Tailscale connected?');
      logger.fatal('  3. Are REDIS_HOST, REDIS_PORT, REDIS_PASSWORD correct in .env?');
    }

    logger.fatal('Server will now exit. Fix the issues and restart.');
    process.exit(1);
  }
});

export default app;