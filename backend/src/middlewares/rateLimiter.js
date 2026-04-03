const rateLimit = require("express-rate-limit");
const ApiError = require("../utils/ApiError");
const config = require("../config/app");

/**
 * General rate limiter
 */
const generalLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.env === "development" ? 10000 : config.rateLimit.maxRequests,
  message: {
    success: false,
    message: "Too many requests, please try again later",
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    next(ApiError.tooManyRequests(options.message.message));
  },
});

/**
 * Strict rate limiter for auth routes
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: config.env === "development" ? 10000 : 10,
  message: {
    success: false,
    message: "Too many login attempts, please try again after 15 minutes",
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Don't count successful requests
  handler: (req, res, next, options) => {
    next(ApiError.tooManyRequests(options.message.message));
  },
});

/**
 * Rate limiter for password reset
 */
const passwordResetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // 5 attempts per hour
  message: {
    success: false,
    message: "Too many password reset attempts, please try again after an hour",
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    next(ApiError.tooManyRequests(options.message.message));
  },
});

/**
 * Rate limiter for registration
 */
const registrationLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: process.env.NODE_ENV === "development" ? 1000 : 5, // unlimited in dev, 5 in production
  message: {
    success: false,
    message: "Too many registration attempts, please try again later",
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, next, options) => {
    next(ApiError.tooManyRequests(options.message.message));
  },
});

module.exports = {
  generalLimiter,
  authLimiter,
  passwordResetLimiter,
  registrationLimiter,
};
