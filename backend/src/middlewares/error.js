const jwt = require("jsonwebtoken");
const { User } = require("../models");
const ApiError = require("../utils/ApiError");
const config = require("../config/app");

/**
 * Middleware to authenticate JWT token
 */
const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw ApiError.unauthorized("Access token is required");
    }

    const token = authHeader.split(" ")[1];

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, config.jwt.secret);
    } catch (error) {
      if (error.name === "TokenExpiredError") {
        throw ApiError.unauthorized("Token has expired");
      }
      throw ApiError.unauthorized("Invalid token");
    }

    // Find user
    const user = await User.findByPk(decoded.id);

    if (!user) {
      throw ApiError.unauthorized("User not found");
    }

    if (user.status !== "active") {
      throw ApiError.forbidden("Account is not active");
    }

    // Attach user to request
    req.user = user;
    req.userId = user.id;

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Optional authentication - doesn't fail if no token
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return next();
    }

    const token = authHeader.split(" ")[1];

    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await User.findByPk(decoded.id);

      if (user && user.status === "active") {
        req.user = user;
        req.userId = user.id;
      }
    } catch (error) {
      // Ignore token errors for optional auth
    }

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware to check if user has required role(s)
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(ApiError.unauthorized("Authentication required"));
    }

    if (!roles.includes(req.user.role)) {
      return next(
        ApiError.forbidden("You do not have permission to perform this action")
      );
    }

    next();
  };
};

/**
 * Middleware to check if user is admin
 */
const isAdmin = (req, res, next) => {
  if (!req.user) {
    return next(ApiError.unauthorized("Authentication required"));
  }

  if (!["admin", "super_admin"].includes(req.user.role)) {
    return next(ApiError.forbidden("Admin access required"));
  }

  next();
};

/**
 * Middleware to check if user is partner
 */
const isPartner = (req, res, next) => {
  if (!req.user) {
    return next(ApiError.unauthorized("Authentication required"));
  }

  if (!["partner", "admin", "super_admin"].includes(req.user.role)) {
    return next(ApiError.forbidden("Partner access required"));
  }

  next();
};

/**
 * Middleware to check if user is super admin
 */
const isSuperAdmin = (req, res, next) => {
  if (!req.user) {
    return next(ApiError.unauthorized("Authentication required"));
  }

  if (req.user.role !== "super_admin") {
    return next(ApiError.forbidden("Super admin access required"));
  }

  next();
};

module.exports = {
  authenticate,
  optionalAuth,
  authorize,
  isAdmin,
  isPartner,
  isSuperAdmin,
};
