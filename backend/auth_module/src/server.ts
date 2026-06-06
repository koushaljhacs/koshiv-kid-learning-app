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
 *
 * Aim: Auth Module Express Server Entry Point
 * Why: Initializes Express app on port 34554 bound to all interfaces (0.0.0.0)
 *      for Tailscale network access. Verifies PostgreSQL and Redis connectivity.
 *      Integrates auth routes at /api/v1/auth/.
 *      Logs every incoming request with method, URL, IP.
 *      Handles 404 routes and global errors with Pino structured logging.
 *      Fails fast (process.exit(1)) if any infrastructure connection fails.
 * ============================================================
 */

import express, { Application, Request, Response, NextFunction } from 'express';
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

// Request logging — every incoming request
app.use((req: Request, _res: Response, next: NextFunction) => {
  logger.info(
    {
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      userAgent: req.get('User-Agent') || 'unknown',
    },
    `Incoming request: ${req.method} ${req.originalUrl}`,
  );
  next();
});

// ============================================================
// ROUTES
// ============================================================

// Health check endpoint
app.get('/health', async (_req: Request, res: Response): Promise<void> => {
  logger.debug('Health check requested');

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
    logger.info(healthData, 'Health check passed');
    res.status(200).json(healthData);
  } else {
    logger.warn(healthData, 'Health check degraded');
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
  logger.warn(
    {
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
    },
    `Route not found: ${req.method} ${req.originalUrl}`,
  );
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl,
    method: req.method,
  });
});

// Global error handler
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  logger.error(
    {
      err: {
        message: err.message,
        stack: err.stack,
        name: err.name,
      },
      method: req.method,
      url: req.originalUrl,
      body: req.body,
    },
    `Unhandled error: ${err.message}`,
  );
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
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
    }, 'PostgreSQL connection FAILED — check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME in .env file at backend/auth_module/.env');
  }

  logger.debug('Step 3/4: Verifying Redis connection...');
  const redisOk = await connectRedis();

  if (redisOk) {
    logger.info({ host: process.env.REDIS_HOST, port: process.env.REDIS_PORT }, 'Redis connected successfully');
  } else {
    logger.fatal({
      host: process.env.REDIS_HOST,
      port: process.env.REDIS_PORT,
    }, 'Redis connection FAILED — check REDIS_HOST, REDIS_PORT, REDIS_PASSWORD in .env file at backend/auth_module/.env');
  }

  logger.debug('Step 4/4: Checking loaded routes...');
  logger.info(
    {
      routes: [
        'GET  /health',
        'POST /api/v1/auth/otp/send',
        'POST /api/v1/auth/otp/verify',
        'POST /api/v1/auth/parent/register/options',
        'POST /api/v1/auth/parent/register/verify',
        'POST /api/v1/auth/child/login',
        'POST /api/v1/auth/token/refresh',
      ],
    },
    'Available API endpoints',
  );

  if (dbOk && redisOk) {
    logger.info('============================================================');
    logger.info('Auth Service Database and Cache connected successfully');
    logger.info({ port: PORT, bind: '0.0.0.0' }, 'Auth Module is ready to accept requests');
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
      logger.fatal(`     Current: DB_HOST=${process.env.DB_HOST}, DB_PORT=${process.env.DB_PORT}`);
    }

    if (!redisOk) {
      logger.fatal('[ACTION REQUIRED] Redis connection failed. Check:');
      logger.fatal('  1. Is Redis Docker container running?');
      logger.fatal('  2. Is Tailscale connected?');
      logger.fatal('  3. Are REDIS_HOST, REDIS_PORT, REDIS_PASSWORD correct in .env?');
      logger.fatal(`     Current: REDIS_HOST=${process.env.REDIS_HOST}, REDIS_PORT=${process.env.REDIS_PORT}`);
    }

    logger.fatal('Server will now exit. Fix the issues and restart.');
    process.exit(1);
  }
});

export default app;