const express = require("express");
const router = express.Router();
const establishmentController = require("../controllers/establishment.controller");
const reviewController = require("../controllers/review.controller");
const { optionalAuth, authenticate } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const { establishmentValidation, reviewValidation } = require("../validations");

/**
 * @route   GET /api/v1/establishments
 * @desc    Search establishments with filters
 * @access  Public
 * @query   q, category_id, subcategory_id, wilaya_id, commune_id, price_range,
 *          is_verified, is_featured, min_rating, latitude, longitude, radius,
 *          services, amenities, tags, sort_by, sort_order, page, limit
 */
router.get(
  "/",
  validate(establishmentValidation.searchQuery),
  establishmentController.search,
);

/**
 * @route   GET /api/v1/establishments/featured
 * @desc    Get featured establishments
 * @access  Public
 * @query   limit
 */
router.get("/featured", establishmentController.getFeatured);

/**
 * @route   GET /api/v1/establishments/nearby
 * @desc    Get nearby establishments
 * @access  Public
 * @query   latitude, longitude, radius, limit
 */
router.get("/nearby", establishmentController.getNearby);

/**
 * @route   GET /api/v1/establishments/category/:categoryId
 * @desc    Get establishments by category
 * @access  Public
 * @query   page, limit, wilaya_id
 */
router.get("/category/:categoryId", establishmentController.getByCategory);

/**
 * @route   GET /api/v1/establishments/wilaya/:wilayaId
 * @desc    Get establishments by wilaya
 * @access  Public
 * @query   page, limit, category_id
 */
router.get("/wilaya/:wilayaId", establishmentController.getByWilaya);

/**
 * @route   GET /api/v1/establishments/slug/:slug
 * @desc    Get establishment by slug
 * @access  Public (optional auth for favorite status)
 */
router.get("/slug/:slug", optionalAuth, establishmentController.getBySlug);

/**
 * @route   GET /api/v1/establishments/:id
 * @desc    Get establishment by ID
 * @access  Public (optional auth for favorite status)
 */
router.get("/:id", optionalAuth, establishmentController.getById);

/**
 * @route   POST /api/v1/establishments/:id/track/phone
 * @desc    Track phone click
 * @access  Public
 */
router.post("/:id/track/phone", establishmentController.trackPhoneClick);

/**
 * @route   POST /api/v1/establishments/:id/track/whatsapp
 * @desc    Track WhatsApp click
 * @access  Public
 */
router.post("/:id/track/whatsapp", establishmentController.trackWhatsAppClick);

/**
 * @route   POST /api/v1/establishments/:id/track/contact
 * @desc    Track contact form submission
 * @access  Public
 */
router.post("/:id/track/contact", establishmentController.trackContact);

// ==================== REVIEW ROUTES ====================

/**
 * @route   GET /api/v1/establishments/:establishmentId/reviews
 * @desc    Get establishment reviews
 * @access  Public
 * @query   page, limit, sort_by, sort_order
 */
router.get(
  "/:establishmentId/reviews",
  reviewController.getEstablishmentReviews,
);

/**
 * @route   POST /api/v1/establishments/:establishmentId/reviews
 * @desc    Create a review
 * @access  Private
 */
router.post(
  "/:establishmentId/reviews",
  authenticate,
  validate(reviewValidation.createReview),
  reviewController.createReview,
);

module.exports = router;
