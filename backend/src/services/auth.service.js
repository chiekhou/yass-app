const jwt = require("jsonwebtoken");
const { User, RefreshToken } = require("../models");
const ApiError = require("../utils/ApiError");
const { generateToken } = require("../utils/helpers");
const config = require("../config/app");

class AuthService {
  /**
   * Generate access token
   */
  generateAccessToken(user) {
    const payload = {
      id: user.id,
      email: user.email,
      role: user.role,
    };

    return jwt.sign(payload, config.jwt.secret, {
      expiresIn: config.jwt.expiresIn,
    });
  }

  /**
   * Generate refresh token
   */
  async generateRefreshToken(user, deviceInfo = null, ipAddress = null) {
    const token = generateToken(64);

    // Calculate expiration
    const expiresAt = new Date();
    const days = parseInt(config.jwt.refreshExpiresIn) || 30;
    expiresAt.setDate(expiresAt.getDate() + days);

    // Save refresh token
    await RefreshToken.create({
      user_id: user.id,
      token,
      expires_at: expiresAt,
      device_info: deviceInfo,
      ip_address: ipAddress,
    });

    return token;
  }

  /**
   * Generate both tokens
   */
  async generateTokens(user, deviceInfo = null, ipAddress = null) {
    const accessToken = this.generateAccessToken(user);
    const refreshToken = await this.generateRefreshToken(
      user,
      deviceInfo,
      ipAddress
    );

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      token_type: "Bearer",
      expires_in: config.jwt.expiresIn,
    };
  }

  /**
   * Register new user
   */
  async register(userData) {
    // Check if email already exists
    const existingUser = await User.findOne({
      where: { email: userData.email },
    });

    if (existingUser) {
      throw ApiError.conflict("Email already registered");
    }

    // Check if phone already exists (if provided)
    if (userData.phone) {
      const existingPhone = await User.findOne({
        where: { phone: userData.phone },
      });

      if (existingPhone) {
        throw ApiError.conflict("Phone number already registered");
      }
    }

    // Create user
    const user = await User.create({
      email: userData.email,
      password: userData.password,
      first_name: userData.first_name,
      last_name: userData.last_name,
      phone: userData.phone || null,
      language: userData.language || "fr",
      wilaya_id: userData.wilaya_id || null,
      email_verification_token: generateToken(32),
    });

    // Generate tokens
    const tokens = await this.generateTokens(user, userData.device_info);

    // TODO: Send verification email

    return {
      user: user.toJSON(),
      tokens,
    };
  }

  /**
   * Login user
   */
  async login(email, password, deviceInfo = null, ipAddress = null) {
    // Find user by email
    const user = await User.findOne({
      where: { email },
    });

    if (!user) {
      throw ApiError.unauthorized("Invalid email or password");
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);

    if (!isPasswordValid) {
      throw ApiError.unauthorized("Invalid email or password");
    }

    // Check if user is active
    if (user.status !== "active") {
      throw ApiError.forbidden(
        "Your account is not active. Please contact support."
      );
    }

    // Update last login
    await user.update({ last_login: new Date() });

    // Generate tokens
    const tokens = await this.generateTokens(user, deviceInfo, ipAddress);

    return {
      user: user.toJSON(),
      tokens,
    };
  }

  /**
   * Refresh access token
   */
  async refreshAccessToken(refreshToken) {
    // Find refresh token
    const tokenRecord = await RefreshToken.findOne({
      where: {
        token: refreshToken,
        is_revoked: false,
      },
      include: [
        {
          model: User,
          as: "user",
        },
      ],
    });

    if (!tokenRecord) {
      throw ApiError.unauthorized("Invalid refresh token");
    }

    // Check if token is expired
    if (new Date() > tokenRecord.expires_at) {
      await tokenRecord.update({ is_revoked: true, revoked_at: new Date() });
      throw ApiError.unauthorized("Refresh token has expired");
    }

    // Check if user is active
    if (tokenRecord.user.status !== "active") {
      throw ApiError.forbidden("Your account is not active");
    }

    // Generate new access token
    const accessToken = this.generateAccessToken(tokenRecord.user);

    return {
      access_token: accessToken,
      token_type: "Bearer",
      expires_in: config.jwt.expiresIn,
    };
  }

  /**
   * Logout user (revoke refresh token)
   */
  async logout(refreshToken) {
    const tokenRecord = await RefreshToken.findOne({
      where: { token: refreshToken },
    });

    if (tokenRecord) {
      await tokenRecord.update({
        is_revoked: true,
        revoked_at: new Date(),
      });
    }

    return true;
  }

  /**
   * Logout from all devices
   */
  async logoutAll(userId) {
    await RefreshToken.update(
      {
        is_revoked: true,
        revoked_at: new Date(),
      },
      {
        where: {
          user_id: userId,
          is_revoked: false,
        },
      }
    );

    return true;
  }

  /**
   * Request password reset
   */
  async forgotPassword(email) {
    const user = await User.findOne({ where: { email } });

    if (!user) {
      // Don't reveal that user doesn't exist
      return true;
    }

    // Generate reset token
    const resetToken = generateToken(32);
    const resetExpires = new Date();
    resetExpires.setHours(resetExpires.getHours() + 1); // 1 hour expiry

    await user.update({
      password_reset_token: resetToken,
      password_reset_expires: resetExpires,
    });

    // TODO: Send password reset email

    return true;
  }

  /**
   * Reset password with token
   */
  async resetPassword(token, newPassword) {
    const user = await User.findOne({
      where: {
        password_reset_token: token,
      },
    });

    if (!user) {
      throw ApiError.badRequest("Invalid or expired reset token");
    }

    if (new Date() > user.password_reset_expires) {
      throw ApiError.badRequest("Reset token has expired");
    }

    // Update password
    await user.update({
      password: newPassword,
      password_reset_token: null,
      password_reset_expires: null,
    });

    // Revoke all refresh tokens
    await this.logoutAll(user.id);

    return true;
  }

  /**
   * Change password (authenticated user)
   */
  async changePassword(userId, currentPassword, newPassword) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    // Verify current password
    const isPasswordValid = await user.comparePassword(currentPassword);

    if (!isPasswordValid) {
      throw ApiError.badRequest("Current password is incorrect");
    }

    // Update password
    await user.update({ password: newPassword });

    // Revoke all refresh tokens
    await this.logoutAll(userId);

    return true;
  }

  /**
   * Verify email
   */
  async verifyEmail(token) {
    const user = await User.findOne({
      where: { email_verification_token: token },
    });

    if (!user) {
      throw ApiError.badRequest("Invalid verification token");
    }

    await user.update({
      email_verified: true,
      email_verification_token: null,
    });

    return true;
  }

  /**
   * Get user profile
   */
  async getProfile(userId) {
    const user = await User.findByPk(userId, {
      include: [
        {
          association: "wilaya",
          attributes: ["id", "name", "name_ar"],
        },
      ],
    });

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    return user.toJSON();
  }

  /**
   * Update user profile
   */
  async updateProfile(userId, updateData) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    // Check if phone is being changed and if it's already taken
    if (updateData.phone && updateData.phone !== user.phone) {
      const existingPhone = await User.findOne({
        where: { phone: updateData.phone },
      });

      if (existingPhone) {
        throw ApiError.conflict("Phone number already in use");
      }
    }

    // Update user
    await user.update(updateData);

    return user.toJSON();
  }

  /**
   * Update FCM token for push notifications
   */
  async updateFcmToken(userId, fcmToken) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    await user.update({ fcm_token: fcmToken });

    return true;
  }
}

module.exports = new AuthService();
