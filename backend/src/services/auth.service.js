const jwt = require("jsonwebtoken");
const { User, Partner, RefreshToken } = require("../models");
const ApiError = require("../utils/ApiError");
const { generateToken } = require("../utils/helpers");
const config = require("../config/app");
const emailService = require("./email.service");
const smsService = require("./sms.service");

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
      ipAddress,
    );

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      token_type: "Bearer",
      expires_in: config.jwt.expiresIn,
    };
  }

  /**
   * Register new user (standard user)
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

    // Create user — status pending until email OTP is verified
    const user = await User.create({
      email: userData.email,
      password: userData.password,
      first_name: userData.first_name,
      last_name: userData.last_name,
      phone: userData.phone || null,
      language: userData.language || "fr",
      age: userData.age || null,
      gender: userData.gender || null,
      wilaya_id: userData.wilaya_id || null,
      role: "user",
      status: "pending",
      email_verified: false,
    });

    // Generate tokens
    const tokens = await this.generateTokens(user, userData.device_info);

    // Send OTP to email
    await this._generateAndSendEmailOtp(user);

    return {
      user: user.toJSON(),
      tokens,
      message:
        "Registration successful. Please check your email for the verification code.",
    };
  }

  /**
   * Register new partner (prestataire)
   */
  async registerPartner(userData, partnerData) {
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

    // Generate email verification token
    const emailVerificationToken = generateToken(32);
    const emailVerificationExpires = new Date();
    emailVerificationExpires.setHours(emailVerificationExpires.getHours() + 24);

    // Create user with role 'partner'
    const user = await User.create({
      email: userData.email,
      password: userData.password,
      first_name: userData.first_name,
      last_name: userData.last_name,
      phone: userData.phone || null,
      language: userData.language || "fr",
      wilaya_id: userData.wilaya_id || null,
      role: "partner",
      status: "pending", // Pending until admin approves
      email_verification_token: emailVerificationToken,
      email_verification_expires: emailVerificationExpires,
    });

    // Create partner profile
    const partner = await Partner.create({
      user_id: user.id,
      company_name: partnerData.company_name,
      registration_number: partnerData.registration_number || null,
      tax_id: partnerData.tax_id || null,
      status: "pending",
      subscription_plan: "free",
    });

    // Generate tokens
    const tokens = await this.generateTokens(user, userData.device_info);

    // Send emails (fire-and-forget — ne bloque pas la réponse)
    emailService.sendVerificationEmail(user, emailVerificationToken).catch(() => {});
    emailService.sendPartnerPendingEmail(user, partner).catch(() => {});
    const adminEmail = "admin@annuaire-dz.com";
    emailService.sendAdminNewPartnerNotification(adminEmail, user, partner).catch(() => {});

    return {
      user: user.toJSON(),
      partner: partner.toJSON(),
      tokens,
      message:
        "Partner registration successful. Your account is pending approval. Please check your email.",
    };
  }

  /**
   * Login user
   */
  async login(email, password, deviceInfo = null, ipAddress = null) {
    // Find user by email
    const user = await User.findOne({
      where: { email },
      include: [
        {
          model: Partner,
          as: "partner_profile",
        },
      ],
    });

    if (!user) {
      throw ApiError.unauthorized("Invalid email or password");
    }

    // Check password
    const isPasswordValid = await user.comparePassword(password);

    if (!isPasswordValid) {
      throw ApiError.unauthorized("Invalid email or password");
    }

    // Check user status
    if (user.status === "suspended") {
      throw ApiError.forbidden(
        "Your account has been suspended. Please contact support.",
      );
    }

    if (user.status === "inactive") {
      throw ApiError.forbidden(
        "Your account is inactive. Please contact support.",
      );
    }

    // For partners, check if approved
    if (user.role === "partner" && user.status === "pending") {
      throw ApiError.forbidden(
        "Your partner account is pending approval. Please wait for admin validation.",
      );
    }

    // Update last login
    await user.update({ last_login: new Date() });

    // Generate tokens
    const tokens = await this.generateTokens(user, deviceInfo, ipAddress);

    // Prepare response
    const response = {
      user: user.toJSON(),
      tokens,
    };

    // Add partner info if applicable
    if (user.partner_profile) {
      response.partner = user.partner_profile.toJSON();
    }

    return response;
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
      },
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
      return {
        message:
          "If your email is registered, you will receive a password reset link.",
      };
    }

    // Generate reset token
    const resetToken = generateToken(32);
    const resetExpires = new Date();
    resetExpires.setHours(resetExpires.getHours() + 1); // 1 hour expiry

    await user.update({
      password_reset_token: resetToken,
      password_reset_expires: resetExpires,
    });

    // Send password reset email (fire-and-forget)
    emailService.sendPasswordResetEmail(user, resetToken).catch(() => {});

    return {
      message:
        "If your email is registered, you will receive a password reset link.",
    };
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

    return {
      message:
        "Password reset successful. Please login with your new password.",
    };
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

    return { message: "Password changed successfully. Please login again." };
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

    // Check if token has expired (if expiration is set)
    if (
      user.email_verification_expires &&
      new Date() > user.email_verification_expires
    ) {
      throw ApiError.badRequest(
        "Verification token has expired. Please request a new one.",
      );
    }

    await user.update({
      email_verified: true,
      email_verification_token: null,
      email_verification_expires: null,
    });

    emailService.sendWelcomeEmail(user).catch(() => {});

    return { message: "Email verified successfully. Welcome to Win!" };
  }

  /**
   * Resend verification email
   */
  async resendVerificationEmail(userId) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    if (user.email_verified) {
      throw ApiError.badRequest("Email is already verified");
    }

    // Generate new token
    const emailVerificationToken = generateToken(32);
    const emailVerificationExpires = new Date();
    emailVerificationExpires.setHours(emailVerificationExpires.getHours() + 24);

    await user.update({
      email_verification_token: emailVerificationToken,
      email_verification_expires: emailVerificationExpires,
    });

    emailService.sendVerificationEmail(user, emailVerificationToken).catch(() => {});

    return { message: "Verification email sent. Please check your inbox." };
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
        {
          model: Partner,
          as: "partner_profile",
        },
      ],
    });

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    const response = {
      user: user.toJSON(),
    };

    if (user.partner_profile) {
      response.partner = user.partner_profile.toJSON();
    }

    return response;
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

    // Fields that can be updated
    const allowedFields = [
      "first_name",
      "last_name",
      "phone",
      "language",
      "wilaya_id",
      "avatar",
    ];
    const filteredData = {};

    allowedFields.forEach((field) => {
      if (updateData[field] !== undefined) {
        filteredData[field] = updateData[field];
      }
    });

    // Update user
    await user.update(filteredData);

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

    return { message: "FCM token updated successfully" };
  }

  /**
   * Register new user with phone number (no email required)
   */
  async registerWithPhone(userData) {
    // Phone is mandatory for this flow
    if (!userData.phone) {
      throw ApiError.badRequest("Phone number is required");
    }

    const existingPhone = await User.findOne({
      where: { phone: userData.phone },
    });
    if (existingPhone) {
      throw ApiError.conflict("Phone number already registered");
    }

    // Check email uniqueness if provided
    if (userData.email) {
      const existingEmail = await User.findOne({
        where: { email: userData.email },
      });
      if (existingEmail) {
        throw ApiError.conflict("Email already registered");
      }
    }

    const user = await User.create({
      email: userData.email || null,
      password: userData.password,
      first_name: userData.first_name,
      last_name: userData.last_name,
      phone: userData.phone,
      language: userData.language || "fr",
      age: userData.age || null,
      gender: userData.gender || null,
      wilaya_id: userData.wilaya_id || null,
      role: "user",
      status: "pending",
      phone_verified: false,
    });

    // Send OTP to verify phone
    await this._generateAndSendOtp(user);

    // Generate tokens
    const tokens = await this.generateTokens(user, userData.device_info);

    return {
      user: user.toJSON(),
      tokens,
      message: `Registration successful. An OTP has been sent to ${userData.phone} to verify your number.`,
    };
  }

  /**
   * Login with phone number + password
   */
  async loginWithPhone(phone, password, deviceInfo = null, ipAddress = null) {
    const user = await User.findOne({
      where: { phone },
      include: [{ model: Partner, as: "partner_profile" }],
    });

    if (!user) {
      throw ApiError.unauthorized("Invalid phone number or password");
    }

    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      throw ApiError.unauthorized("Invalid phone number or password");
    }

    if (user.status === "suspended") {
      throw ApiError.forbidden(
        "Your account has been suspended. Please contact support.",
      );
    }

    if (user.status === "inactive") {
      throw ApiError.forbidden(
        "Your account is inactive. Please contact support.",
      );
    }

    if (user.role === "partner" && user.status === "pending") {
      throw ApiError.forbidden("Your partner account is pending approval.");
    }

    await user.update({ last_login: new Date() });

    const tokens = await this.generateTokens(user, deviceInfo, ipAddress);

    const response = { user: user.toJSON(), tokens };
    if (user.partner_profile) {
      response.partner = user.partner_profile.toJSON();
    }

    return response;
  }

  /**
   * Send OTP to the authenticated user's phone
   */
  async sendPhoneOtp(userId) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    if (!user.phone) {
      throw ApiError.badRequest("No phone number associated with this account");
    }

    if (user.phone_verified) {
      throw ApiError.badRequest("Phone number is already verified");
    }

    await this._generateAndSendOtp(user);

    return { message: `OTP sent to ${user.phone}` };
  }

  /**
   * Verify the OTP submitted by the user
   */
  async verifyPhoneOtp(userId, otp) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    if (user.phone_verified) {
      throw ApiError.badRequest("Phone number is already verified");
    }

    if (!user.phone_otp || !user.phone_otp_expires) {
      throw ApiError.badRequest(
        "No OTP was requested. Please request a new one.",
      );
    }

    if (new Date() > user.phone_otp_expires) {
      await user.update({ phone_otp: null, phone_otp_expires: null });
      throw ApiError.badRequest("OTP has expired. Please request a new one.");
    }

    if (user.phone_otp !== otp) {
      throw ApiError.badRequest("Invalid OTP");
    }

    await user.update({
      phone_verified: true,
      phone_otp: null,
      phone_otp_expires: null,
      status: "active",
    });

    return {
      message:
        "Phone number verified successfully. Your account is now active.",
    };
  }

  /**
   * Send OTP to the authenticated user's email
   */
  async sendEmailOtp(userId) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    if (!user.email) {
      throw ApiError.badRequest(
        "No email address associated with this account",
      );
    }

    if (user.email_verified) {
      throw ApiError.badRequest("Email is already verified");
    }

    await this._generateAndSendEmailOtp(user);

    return { message: `Verification code sent to ${user.email}` };
  }

  /**
   * Verify the email OTP submitted by the user
   */
  async verifyEmailOtp(userId, otp) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    if (user.email_verified) {
      throw ApiError.badRequest("Email is already verified");
    }

    if (!user.email_otp || !user.email_otp_expires) {
      throw ApiError.badRequest(
        "No verification code was requested. Please request a new one.",
      );
    }

    if (new Date() > user.email_otp_expires) {
      await user.update({ email_otp: null, email_otp_expires: null });
      throw ApiError.badRequest(
        "Verification code has expired. Please request a new one.",
      );
    }

    if (user.email_otp !== otp) {
      throw ApiError.badRequest("Invalid verification code");
    }

    await user.update({
      email_verified: true,
      email_otp: null,
      email_otp_expires: null,
      status: "active",
    });

    emailService.sendWelcomeEmail(user).catch(() => {});

    return {
      message: "Email verified successfully. Your account is now active.",
    };
  }

  /**
   * Internal helper: generate a 6-digit OTP, save it, and send via email
   */
  async _generateAndSendEmailOtp(user) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 10); // 10 minutes

    await user.update({ email_otp: otp, email_otp_expires: expires });
    await emailService.sendEmailOtp(user, otp);

    return { otp };
  }

  /**
   * Internal helper: generate a 6-digit OTP, save it, and send via SMS
   */
  async _generateAndSendOtp(user) {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 10); // 10 minutes

    await user.update({ phone_otp: otp, phone_otp_expires: expires });
    // Fire-and-forget — un échec SMS ne bloque pas l'inscription
    smsService.sendOtp(user.phone, otp).catch(() => {});

    return { otp };
  }

  /**
   * Update partner profile (company info)
   */
  async updatePartnerProfile(userId, partnerData) {
    const user = await User.findByPk(userId, {
      include: [
        {
          model: Partner,
          as: "partner_profile",
        },
      ],
    });

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    if (user.role !== "partner") {
      throw ApiError.forbidden("Only partners can update partner profile");
    }

    if (!user.partner_profile) {
      throw ApiError.notFound("Partner profile not found");
    }

    // Fields that can be updated
    const allowedFields = ["company_name", "registration_number", "tax_id"];
    const filteredData = {};

    allowedFields.forEach((field) => {
      if (partnerData[field] !== undefined) {
        filteredData[field] = partnerData[field];
      }
    });

    // Update partner profile
    await user.partner_profile.update(filteredData);

    return {
      partner: user.partner_profile.toJSON(),
      message: "Partner profile updated successfully",
    };
  }
}

module.exports = new AuthService();
