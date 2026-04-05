const express = require("express");
const router = express.Router();
const { authController } = require("../controllers");
const { authenticate, authenticatePending } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const { authValidation } = require("../validations");
const {
  authLimiter,
  passwordResetLimiter,
  registrationLimiter,
} = require("../middlewares/rateLimiter");

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user (standard user)
 * @access  Public
 */
router.post(
  "/register",
  registrationLimiter,
  validate(authValidation.register),
  authController.register,
);

/**
 * @route   POST /api/v1/auth/register/partner
 * @desc    Register a new partner (prestataire)
 * @access  Public
 */
router.post(
  "/register/partner",
  registrationLimiter,
  validate(authValidation.registerPartner),
  authController.registerPartner,
);

/**
 * @route   POST /api/v1/auth/register/phone
 * @desc    Register a new user with phone number (no email required)
 * @access  Public
 */
router.post(
  "/register/phone",
  registrationLimiter,
  validate(authValidation.registerWithPhone),
  authController.registerWithPhone,
);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user (user or partner)
 * @access  Public
 */
router.post(
  "/login",
  authLimiter,
  validate(authValidation.login),
  authController.login,
);

/**
 * @route   POST /api/v1/auth/login/phone
 * @desc    Login with phone number + password
 * @access  Public
 */
router.post(
  "/login/phone",
  authLimiter,
  validate(authValidation.loginWithPhone),
  authController.loginWithPhone,
);

/**
 * @route   POST /api/v1/auth/email/send-otp
 * @desc    Send OTP to the authenticated user's email
 * @access  Private
 */
router.post("/email/send-otp", authenticatePending, authController.sendEmailOtp);

/**
 * @route   POST /api/v1/auth/email/verify-otp
 * @desc    Verify email OTP code to confirm email ownership
 * @access  Private (pending allowed)
 */
router.post(
  "/email/verify-otp",
  authenticatePending,
  validate(authValidation.verifyEmailOtp),
  authController.verifyEmailOtp,
);

/**
 * @route   POST /api/v1/auth/phone/send-otp
 * @desc    Send OTP to the authenticated user's phone
 * @access  Private (pending allowed)
 */
router.post("/phone/send-otp", authenticatePending, authController.sendPhoneOtp);

/**
 * @route   POST /api/v1/auth/phone/verify-otp
 * @desc    Verify OTP code to confirm phone ownership
 * @access  Private (pending allowed)
 */
router.post(
  "/phone/verify-otp",
  authenticatePending,
  validate(authValidation.verifyPhoneOtp),
  authController.verifyPhoneOtp,
);

/**
 * @route   POST /api/v1/auth/refresh
 * @desc    Refresh access token
 * @access  Public
 */
router.post(
  "/refresh",
  validate(authValidation.refreshToken),
  authController.refreshToken,
);

/**
 * @route   POST /api/v1/auth/logout
 * @desc    Logout user (revoke refresh token)
 * @access  Public
 */
router.post("/logout", authController.logout);

/**
 * @route   POST /api/v1/auth/logout-all
 * @desc    Logout from all devices
 * @access  Private
 */
router.post("/logout-all", authenticate, authController.logoutAll);

/**
 * @route   POST /api/v1/auth/forgot-password
 * @desc    Request password reset (email)
 * @access  Public
 */
router.post(
  "/forgot-password",
  passwordResetLimiter,
  validate(authValidation.forgotPassword),
  authController.forgotPassword,
);

/**
 * @route   POST /api/v1/auth/forgot-password/phone
 * @desc    Request password reset via phone OTP
 * @access  Public
 */
router.post(
  "/forgot-password/phone",
  passwordResetLimiter,
  validate(authValidation.forgotPasswordByPhone),
  authController.forgotPasswordByPhone,
);

/**
 * @route   POST /api/v1/auth/reset-password
 * @desc    Reset password with token (email)
 * @access  Public
 */
router.post(
  "/reset-password",
  validate(authValidation.resetPassword),
  authController.resetPassword,
);

/**
 * @route   POST /api/v1/auth/reset-password/phone
 * @desc    Reset password via phone OTP
 * @access  Public
 */
router.post(
  "/reset-password/phone",
  validate(authValidation.resetPasswordByPhone),
  authController.resetPasswordByPhone,
);

/**
 * @route   POST /api/v1/auth/change-password
 * @desc    Change password (authenticated user)
 * @access  Private
 */
router.post(
  "/change-password",
  authenticate,
  validate(authValidation.changePassword),
  authController.changePassword,
);

/**
 * @route   GET /api/v1/auth/verify-email/:token
 * @desc    Verify email address
 * @access  Public
 */
router.get("/verify-email/:token", authController.verifyEmail);

/**
 * @route   POST /api/v1/auth/resend-verification
 * @desc    Resend verification email
 * @access  Private
 */
router.post(
  "/resend-verification",
  authenticate,
  authController.resendVerificationEmail,
);

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get("/me", authenticate, authController.getProfile);

/**
 * @route   PUT /api/v1/auth/me
 * @desc    Update current user profile
 * @access  Private
 */
router.put(
  "/me",
  authenticate,
  validate(authValidation.updateProfile),
  authController.updateProfile,
);

/**
 * @route   PUT /api/v1/auth/fcm-token
 * @desc    Update FCM token for push notifications
 * @access  Private
 */
router.put("/fcm-token", authenticate, authController.updateFcmToken);

/**
 * @route   PUT /api/v1/auth/partner-profile
 * @desc    Update partner profile (company info)
 * @access  Private (Partner only)
 */
router.put(
  "/partner-profile",
  authenticate,
  validate(authValidation.updatePartnerProfile),
  authController.updatePartnerProfile
);

module.exports = router;
