const { validationResult } = require("express-validator");
const ApiError = require("../utils/ApiError");

/**
 * Middleware to validate request using express-validator
 */
const validate = (validations) => {
  return async (req, res, next) => {
    // Run all validations
    await Promise.all(validations.map((validation) => validation.run(req)));

    // Check for errors
    const errors = validationResult(req);

    if (errors.isEmpty()) {
      return next();
    }

    // Format errors
    const formattedErrors = errors.array().map((error) => ({
      field: error.path,
      message: error.msg,
    }));

    // Get first error message for the main message
    const firstError = formattedErrors[0].message;

    // Return error response
    return res.status(400).json({
      success: false,
      message: firstError,
      errors: formattedErrors,
    });
  };
};

module.exports = validate;
