const { body, param, query } = require("express-validator");

const register = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Password must be at least 8 characters long")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Password must contain at least one uppercase letter, one lowercase letter, and one number"
    ),

  body("first_name")
    .trim()
    .notEmpty()
    .withMessage("First name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("First name must be between 2 and 100 characters"),

  body("last_name")
    .trim()
    .notEmpty()
    .withMessage("Last name is required")
    .isLength({ min: 2, max: 100 })
    .withMessage("Last name must be between 2 and 100 characters"),

  body("phone")
    .optional()
    .trim()
    .isMobilePhone("ar-DZ")
    .withMessage("Please provide a valid Algerian phone number"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("Language must be fr, ar, or en"),
];

const login = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("password").notEmpty().withMessage("Password is required"),
];

const forgotPassword = [
  body("email")
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),
];

const resetPassword = [
  body("token").notEmpty().withMessage("Reset token is required"),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Password must be at least 8 characters long")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Password must contain at least one uppercase letter, one lowercase letter, and one number"
    ),
];

const changePassword = [
  body("current_password")
    .notEmpty()
    .withMessage("Current password is required"),

  body("new_password")
    .isLength({ min: 8 })
    .withMessage("New password must be at least 8 characters long")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "New password must contain at least one uppercase letter, one lowercase letter, and one number"
    ),
];

const refreshToken = [
  body("refresh_token").notEmpty().withMessage("Refresh token is required"),
];

const updateProfile = [
  body("first_name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage("First name must be between 2 and 100 characters"),

  body("last_name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage("Last name must be between 2 and 100 characters"),

  body("phone")
    .optional()
    .trim()
    .isMobilePhone("ar-DZ")
    .withMessage("Please provide a valid Algerian phone number"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("Language must be fr, ar, or en"),

  body("wilaya_id").optional().isUUID(4).withMessage("Invalid wilaya ID"),
];

module.exports = {
  register,
  login,
  forgotPassword,
  resetPassword,
  changePassword,
  refreshToken,
  updateProfile,
};
