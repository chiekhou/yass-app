const { Partner } = require("../models");
const ApiError = require("../utils/ApiError");

/**
 * Middleware to check if user is a partner and attach partner ID
 */
const loadPartner = async (req, res, next) => {
  try {
    // User must be authenticated first
    if (!req.userId) {
      throw ApiError.unauthorized("Authentication required");
    }

    // User must have partner role
    if (req.user.role !== "partner") {
      throw ApiError.forbidden("Partner access required");
    }

    // Find partner profile
    const partner = await Partner.findOne({
      where: { user_id: req.userId },
    });

    if (!partner) {
      throw ApiError.notFound("Partner profile not found");
    }

    // Check partner status
    if (partner.status !== "approved") {
      throw ApiError.forbidden(
        `Partner account is ${partner.status}. Access denied.`,
      );
    }

    // Attach partner ID to request
    req.partnerId = partner.id;
    req.partner = partner;

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware to optionally load partner (for routes that need partner info if available)
 */
const optionalLoadPartner = async (req, res, next) => {
  try {
    if (req.userId && req.user && req.user.role === "partner") {
      const partner = await Partner.findOne({
        where: { user_id: req.userId, status: "approved" },
      });

      if (partner) {
        req.partnerId = partner.id;
        req.partner = partner;
      }
    }

    next();
  } catch (error) {
    next(error);
  }
};

module.exports = {
  loadPartner,
  optionalLoadPartner,
};
