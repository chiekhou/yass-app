const { body } = require("express-validator");

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
      "Password must contain at least one uppercase letter, one lowercase letter, and one number",
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
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Please provide a valid phone number (e.g. 0551234567 or +33612345678)"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("Language must be fr, ar, or en"),

  body("wilaya_id").optional().isUUID(4).withMessage("Invalid wilaya ID"),
];

const registerPartner = [
  // User fields
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
      "Password must contain at least one uppercase letter, one lowercase letter, and one number",
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
    .trim()
    .notEmpty()
    .withMessage("Phone number is required for partners")
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Please provide a valid phone number (e.g. 0551234567 or +33612345678)"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("Language must be fr, ar, or en"),

  body("wilaya_id").optional().isUUID(4).withMessage("Invalid wilaya ID"),

  // Partner fields
  body("company_name")
    .trim()
    .notEmpty()
    .withMessage("Company name is required")
    .isLength({ min: 2, max: 255 })
    .withMessage("Company name must be between 2 and 255 characters"),

  body("registration_number")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Registration number must be less than 100 characters"),

  body("tax_id")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Tax ID must be less than 100 characters"),
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
      "Password must contain at least one uppercase letter, one lowercase letter, and one number",
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
      "New password must contain at least one uppercase letter, one lowercase letter, and one number",
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
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Please provide a valid phone number (e.g. 0551234567 or +33612345678)"),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("Language must be fr, ar, or en"),

  body("wilaya_id").optional().isUUID(4).withMessage("Invalid wilaya ID"),
];

const updatePartnerProfile = [
  body("company_name")
    .optional()
    .trim()
    .isLength({ min: 2, max: 255 })
    .withMessage("Company name must be between 2 and 255 characters"),

  body("registration_number")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Registration number must be less than 100 characters"),

  body("tax_id")
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage("Tax ID must be less than 100 characters"),
];

const registerWithPhone = [
  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Phone number is required")
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Please provide a valid phone number (e.g. 0551234567 or +33612345678)"),

  body("password")
    .isLength({ min: 8 })
    .withMessage("Password must be at least 8 characters long")
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage(
      "Password must contain at least one uppercase letter, one lowercase letter, and one number",
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

  body("email")
    .optional({ nullable: true, checkFalsy: true })
    .trim()
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("language")
    .optional()
    .isIn(["fr", "ar", "en"])
    .withMessage("Language must be fr, ar, or en"),

  body("wilaya_id").optional().isUUID(4).withMessage("Invalid wilaya ID"),
];

const loginWithPhone = [
  body("phone")
    .trim()
    .notEmpty()
    .withMessage("Phone number is required")
    .matches(/^\+?[0-9]\d{6,14}$/)
    .withMessage("Please provide a valid phone number (e.g. 0551234567 or +33612345678)"),

  body("password").notEmpty().withMessage("Password is required"),
];

const verifyPhoneOtp = [
  body("otp")
    .trim()
    .notEmpty()
    .withMessage("OTP is required")
    .isLength({ min: 6, max: 6 })
    .withMessage("OTP must be exactly 6 digits")
    .isNumeric()
    .withMessage("OTP must contain only digits"),
];

// Email OTP uses the same 6-digit validation rules as phone OTP
const verifyEmailOtp = verifyPhoneOtp;

module.exports = {
  register,
  registerPartner,
  registerWithPhone,
  login,
  loginWithPhone,
  forgotPassword,
  resetPassword,
  changePassword,
  refreshToken,
  updateProfile,
  updatePartnerProfile,
  verifyPhoneOtp,
  verifyEmailOtp,
};
