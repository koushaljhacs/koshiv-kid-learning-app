/**
 * ============================================================
 * Developer Name: Koushal Jha
 * Developer Email: koushaljha.cs@gmail.com
 * Project Name: koshiv - Learning App for Kids
 * Role: Backend Developer
 * Module: auth_module
 * File: src/middlewares/auth.middleware.ts
 * Original File Version: 1.0.0
 * Complete Version Tracing:
 * Version 1.0.0 | Initial Auth middleware — JWT verification and role-based access control
 *
 * Aim: Authentication & Authorization Middleware
 * Why: Validates JWT access token from Authorization header.
 *      Extracts user payload and attaches to request.
 *      Provides role-based access control for parent/child routes.
 * ============================================================
 */

import { Request, Response, NextFunction } from 'express';
import pino from 'pino';
import { verifyAccessToken, TokenPayload } from '../services/jwt.service';

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

// Extend Express Request to include user payload
declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

/**
 * Middleware: Verify JWT access token.
 * Attaches decoded payload to req.user on success.
 */
export const authenticate = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    logger.warn('Authentication failed — no authorization header');
    res.status(401).json({ error: 'Authorization header is required' });
    return;
  }

  const parts = authHeader.split(' ');

  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    logger.warn('Authentication failed — invalid authorization format');
    res.status(401).json({ error: 'Invalid authorization format. Use: Bearer <token>' });
    return;
  }

  const token = parts[1];

  try {
    const decoded = verifyAccessToken(token);
    req.user = decoded;
    logger.debug({ sub: decoded.sub, role: decoded.role }, 'User authenticated');
    next();
  } catch (error) {
    logger.warn({ err: error }, 'Authentication failed — invalid or expired token');
    res.status(401).json({ error: 'Invalid or expired access token' });
  }
};

/**
 * Middleware: Authorize by role.
 * Must be used after authenticate middleware.
 */
export const authorize = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      logger.warn('Authorization failed — no user on request');
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    if (!roles.includes(req.user.role)) {
      logger.warn({ userRole: req.user.role, requiredRoles: roles }, 'Authorization failed — insufficient permissions');
      res.status(403).json({ error: 'Insufficient permissions' });
      return;
    }

    logger.debug({ role: req.user.role }, 'User authorized');
    next();
  };
};