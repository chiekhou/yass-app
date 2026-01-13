const express = require("express");
const router = express.Router();
const { authController } = require("../controllers");
const { authenticate } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const { authValidation } = require("../validations");
const {
  authLimiter,
  passwordResetLimiter,
  registrationLimiter,
} = require("../middlewares/rateLimiter");

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post(
  "/register",
  registrationLimiter,
  validate(authValidation.register),
  authController.register
);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post(
  "/login",
  authLimiter,
  validate(authValidation.login),
  authController.login
);

/**
 * @route   POST /api/v1/auth/refresh
 * @desc    Refresh access token
 * @access  Public
 */
router.post(
  "/refresh",
  validate(authValidation.refreshToken),
  authController.refreshToken
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
 * @desc    Request password reset
 * @access  Public
 */
router.post(
  "/forgot-password",
  passwordResetLimiter,
  validate(authValidation.forgotPassword),
  authController.forgotPassword
);

/**
 * @route   POST /api/v1/auth/reset-password
 * @desc    Reset password with token
 * @access  Public
 */
router.post(
  "/reset-password",
  validate(authValidation.resetPassword),
  authController.resetPassword
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
  authController.changePassword
);

/**
 * @route   GET /api/v1/auth/verify-email/:token
 * @desc    Verify email address
 * @access  Public
 */
router.get("/verify-email/:token", authController.verifyEmail);

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
  authController.updateProfile
);

/**
 * @route   PUT /api/v1/auth/fcm-token
 * @desc    Update FCM token for push notifications
 * @access  Private
 */
router.put("/fcm-token", authenticate, authController.updateFcmToken);

module.exports = router;
