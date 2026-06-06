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
 * Version 1.0.0 | Commit: <commit-hash> | Initial Express server — port 34554, DB + Redis health check, Pino logger
 *
 * Aim: Auth Module Express Server Entry Point
 * Why: Initializes Express app on port 34554, verifies PostgreSQL
 *      and Redis connectivity on startup using Pino structured logger.
 *      Exposes /health endpoint for infrastructure monitoring.
 *      Fails fast (process.exit(1)) if any connection fails.
 * ============================================================
 */

import express, { Application, Request, Response } from 'express';
import dotenv from 'dotenv';
import pino from 'pino';
import { connectDb } from './config/db';
import { connectRedis } from './config/redis';

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

app.use(express.json());

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

app.listen(PORT, async (): Promise<void> => {
  logger.info({ port: PORT }, 'Auth Module server starting');

  logger.debug('Verifying database connection...');
  const dbOk = await connectDb();

  logger.debug('Verifying Redis connection...');
  const redisOk = await connectRedis();

  if (dbOk && redisOk) {
    logger.info('Auth Service Database and Cache connected successfully');
    logger.info({ port: PORT }, 'Auth Module is ready to accept requests');
  } else {
    logger.fatal('Infrastructure connection failed. Server cannot start.');

    if (!dbOk) {
      logger.fatal('PostgreSQL connection failed. Check DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME in .env');
    }

    if (!redisOk) {
      logger.fatal('Redis connection failed. Check REDIS_HOST, REDIS_PORT, REDIS_PASSWORD in .env');
    }

    process.exit(1);
  }
});

export default app;