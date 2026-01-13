const { authService } = require("../services");
const { ApiResponse } = require("../utils");

class AuthController {
  /**
   * Register new user
   * POST /api/v1/auth/register
   */
  async register(req, res, next) {
    try {
      const deviceInfo = {
        user_agent: req.headers["user-agent"],
        platform: req.body.platform || "unknown",
      };

      const result = await authService.register({
        ...req.body,
        device_info: deviceInfo,
      });

      ApiResponse.created(result, "Registration successful").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Login user
   * POST /api/v1/auth/login
   */
  async login(req, res, next) {
    try {
      const { email, password } = req.body;
      const deviceInfo = {
        user_agent: req.headers["user-agent"],
        platform: req.body.platform || "unknown",
      };
      const ipAddress = req.ip || req.connection.remoteAddress;

      const result = await authService.login(
        email,
        password,
        deviceInfo,
        ipAddress
      );

      ApiResponse.success(result, "Login successful").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Refresh access token
   * POST /api/v1/auth/refresh
   */
  async refreshToken(req, res, next) {
    try {
      const { refresh_token } = req.body;

      const result = await authService.refreshAccessToken(refresh_token);

      ApiResponse.success(result, "Token refreshed successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Logout user
   * POST /api/v1/auth/logout
   */
  async logout(req, res, next) {
    try {
      const { refresh_token } = req.body;

      await authService.logout(refresh_token);

      ApiResponse.success(null, "Logout successful").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Logout from all devices
   * POST /api/v1/auth/logout-all
   */
  async logoutAll(req, res, next) {
    try {
      await authService.logoutAll(req.userId);

      ApiResponse.success(null, "Logged out from all devices").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Request password reset
   * POST /api/v1/auth/forgot-password
   */
  async forgotPassword(req, res, next) {
    try {
      const { email } = req.body;

      await authService.forgotPassword(email);

      ApiResponse.success(
        null,
        "If your email is registered, you will receive a password reset link"
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Reset password with token
   * POST /api/v1/auth/reset-password
   */
  async resetPassword(req, res, next) {
    try {
      const { token, password } = req.body;

      await authService.resetPassword(token, password);

      ApiResponse.success(null, "Password reset successful").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Change password (authenticated)
   * POST /api/v1/auth/change-password
   */
  async changePassword(req, res, next) {
    try {
      const { current_password, new_password } = req.body;

      await authService.changePassword(
        req.userId,
        current_password,
        new_password
      );

      ApiResponse.success(null, "Password changed successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verify email
   * GET /api/v1/auth/verify-email/:token
   */
  async verifyEmail(req, res, next) {
    try {
      const { token } = req.params;

      await authService.verifyEmail(token);

      ApiResponse.success(null, "Email verified successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get current user profile
   * GET /api/v1/auth/me
   */
  async getProfile(req, res, next) {
    try {
      const user = await authService.getProfile(req.userId);

      ApiResponse.success(user, "Profile retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update current user profile
   * PUT /api/v1/auth/me
   */
  async updateProfile(req, res, next) {
    try {
      const user = await authService.updateProfile(req.userId, req.body);

      ApiResponse.success(user, "Profile updated successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update FCM token for push notifications
   * PUT /api/v1/auth/fcm-token
   */
  async updateFcmToken(req, res, next) {
    try {
      const { fcm_token } = req.body;

      await authService.updateFcmToken(req.userId, fcm_token);

      ApiResponse.success(null, "FCM token updated successfully").send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
