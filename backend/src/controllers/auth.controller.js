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

      ApiResponse.created(result, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Register new partner (prestataire)
   * POST /api/v1/auth/register/partner
   */
  async registerPartner(req, res, next) {
    try {
      const deviceInfo = {
        user_agent: req.headers["user-agent"],
        platform: req.body.platform || "unknown",
      };

      // Separate user data from partner data
      const userData = {
        email: req.body.email,
        password: req.body.password,
        first_name: req.body.first_name,
        last_name: req.body.last_name,
        phone: req.body.phone,
        language: req.body.language,
        wilaya_id: req.body.wilaya_id,
        device_info: deviceInfo,
      };

      const partnerData = {
        company_name: req.body.company_name,
        registration_number: req.body.registration_number,
        tax_id: req.body.tax_id,
      };

      const result = await authService.registerPartner(userData, partnerData);

      ApiResponse.created(result, result.message).send(res);
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
        ipAddress,
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

      const result = await authService.forgotPassword(email);

      ApiResponse.success(null, result.message).send(res);
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

      const result = await authService.resetPassword(token, password);

      ApiResponse.success(null, result.message).send(res);
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

      const result = await authService.changePassword(
        req.userId,
        current_password,
        new_password,
      );

      ApiResponse.success(null, result.message).send(res);
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

      const result = await authService.verifyEmail(token);

      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Send OTP to user's email for verification
   * POST /api/v1/auth/email/send-otp
   */
  async sendEmailOtp(req, res, next) {
    try {
      const result = await authService.sendEmailOtp(req.userId);

      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verify email OTP code
   * POST /api/v1/auth/email/verify-otp
   */
  async verifyEmailOtp(req, res, next) {
    try {
      const { otp } = req.body;

      const result = await authService.verifyEmailOtp(req.userId, otp);

      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Resend verification email
   * POST /api/v1/auth/resend-verification
   */
  async resendVerificationEmail(req, res, next) {
    try {
      const result = await authService.resendVerificationEmail(req.userId);

      ApiResponse.success(null, result.message).send(res);
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
      const result = await authService.getProfile(req.userId);

      ApiResponse.success(result, "Profile retrieved successfully").send(res);
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

      const result = await authService.updateFcmToken(req.userId, fcm_token);

      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Register new user with phone number
   * POST /api/v1/auth/register/phone
   */
  async registerWithPhone(req, res, next) {
    try {
      const deviceInfo = {
        user_agent: req.headers["user-agent"],
        platform: req.body.platform || "unknown",
      };

      const result = await authService.registerWithPhone({
        ...req.body,
        device_info: deviceInfo,
      });

      ApiResponse.created(result, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Login with phone number + password
   * POST /api/v1/auth/login/phone
   */
  async loginWithPhone(req, res, next) {
    try {
      const { phone, password } = req.body;
      const deviceInfo = {
        user_agent: req.headers["user-agent"],
        platform: req.body.platform || "unknown",
      };
      const ipAddress = req.ip || req.connection.remoteAddress;

      const result = await authService.loginWithPhone(phone, password, deviceInfo, ipAddress);

      ApiResponse.success(result, "Login successful").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Send OTP to user's phone
   * POST /api/v1/auth/phone/send-otp
   */
  async sendPhoneOtp(req, res, next) {
    try {
      const result = await authService.sendPhoneOtp(req.userId);

      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verify OTP code
   * POST /api/v1/auth/phone/verify-otp
   */
  async verifyPhoneOtp(req, res, next) {
    try {
      const { otp } = req.body;

      const result = await authService.verifyPhoneOtp(req.userId, otp);

      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update partner profile (company info)
   * PUT /api/v1/auth/partner-profile
   */
  async updatePartnerProfile(req, res, next) {
    try {
      const result = await authService.updatePartnerProfile(
        req.userId,
        req.body
      );

      ApiResponse.success(result.partner, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
