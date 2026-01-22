const ApiError = require("../utils/ApiError");
const config = require("../config/app");

/**
 * Convert non-ApiError to ApiError
 */
const errorConverter = (err, req, res, next) => {
  let error = err;

  if (!(error instanceof ApiError)) {
    const statusCode = error.statusCode || 500;
    const message = error.message || "Internal Server Error";
    error = new ApiError(statusCode, message, false, err.stack);
  }

  next(error);
};

/**
 * Handle errors and send response
 */
const errorHandler = (err, req, res, next) => {
  let { statusCode, message } = err;

  // In production, don't leak error details for non-operational errors
  if (config.env === "production" && !err.isOperational) {
    statusCode = 500;
    message = "Internal Server Error";
  }

  // Log error in development
  if (config.env === "development") {
    console.error("Error:", err);
  }

  const response = {
    success: false,
    message,
    ...(config.env === "development" && { stack: err.stack }),
  };

  res.status(statusCode).json(response);
};

/**
 * Handle 404 Not Found
 */
const notFound = (req, res, next) => {
  next(ApiError.notFound(`Route ${req.originalUrl} not found`));
};

/**
 * Handle Sequelize errors
 */
const sequelizeErrorHandler = (err, req, res, next) => {
  let error = err;

  // Sequelize validation error
  if (err.name === "SequelizeValidationError") {
    const messages = err.errors.map((e) => e.message).join(", ");
    error = ApiError.badRequest(messages);
  }

  // Sequelize unique constraint error
  if (err.name === "SequelizeUniqueConstraintError") {
    const field = err.errors[0]?.path || "field";
    error = ApiError.conflict(`${field} already exists`);
  }

  // Sequelize foreign key constraint error
  if (err.name === "SequelizeForeignKeyConstraintError") {
    error = ApiError.badRequest("Invalid reference to related resource");
  }

  // Sequelize database error
  if (err.name === "SequelizeDatabaseError") {
    if (config.env === "development") {
      error = ApiError.internal(err.message);
    } else {
      error = ApiError.internal("Database error");
    }
  }

  next(error);
};

module.exports = {
  errorConverter,
  errorHandler,
  notFound,
  sequelizeErrorHandler,
};
