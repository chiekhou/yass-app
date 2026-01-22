const express = require("express");
const router = express.Router();
const establishmentController = require("../controllers/establishment.controller");
const reviewController = require("../controllers/review.controller");
const uploadController = require("../controllers/upload.controller");
const { authenticate } = require("../middlewares/auth");
const { loadPartner } = require("../middlewares/partner");
const validate = require("../middlewares/validate");
const { establishmentValidation, reviewValidation } = require("../validations");
const { logoUpload, coverUpload, galleryUpload } = require("../config/upload");

// All partner routes require authentication and partner role
router.use(authenticate);
router.use(loadPartner);

/**
 * @route   GET /api/v1/partner/stats
 * @desc    Get partner statistics
 * @access  Partner
 */
router.get("/stats", establishmentController.getStats);

/**
 * @route   GET /api/v1/partner/establishments
 * @desc    Get my establishments
 * @access  Partner
 * @query   page, limit, status
 */
router.get("/establishments", establishmentController.getMyEstablishments);

/**
 * @route   GET /api/v1/partner/establishments/:id
 * @desc    Get my establishment by ID
 * @access  Partner
 */
router.get(
  "/establishments/:id",
  establishmentController.getMyEstablishmentById,
);

/**
 * @route   POST /api/v1/partner/establishments
 * @desc    Create new establishment
 * @access  Partner
 */
router.post(
  "/establishments",
  validate(establishmentValidation.createEstablishment),
  establishmentController.create,
);

/**
 * @route   PUT /api/v1/partner/establishments/:id
 * @desc    Update establishment
 * @access  Partner
 */
router.put(
  "/establishments/:id",
  validate(establishmentValidation.updateEstablishment),
  establishmentController.update,
);

/**
 * @route   DELETE /api/v1/partner/establishments/:id
 * @desc    Delete establishment
 * @access  Partner
 */
router.delete("/establishments/:id", establishmentController.delete);

/**
 * @route   PATCH /api/v1/partner/establishments/:id/status
 * @desc    Update establishment status (deactivate/reactivate)
 * @access  Partner
 */
router.patch(
  "/establishments/:id/status",
  validate(establishmentValidation.updateStatus),
  establishmentController.updateStatus,
);

// ==================== UPLOAD ROUTES ====================

/**
 * @route   POST /api/v1/partner/establishments/:id/logo
 * @desc    Upload establishment logo
 * @access  Partner
 * @body    FormData with 'logo' field
 */
router.post(
  "/establishments/:id/logo",
  logoUpload,
  uploadController.uploadLogo,
);

/**
 * @route   POST /api/v1/partner/establishments/:id/cover
 * @desc    Upload establishment cover image
 * @access  Partner
 * @body    FormData with 'cover' field
 */
router.post(
  "/establishments/:id/cover",
  coverUpload,
  uploadController.uploadCover,
);

/**
 * @route   POST /api/v1/partner/establishments/:id/gallery
 * @desc    Upload gallery images (max 10 at a time)
 * @access  Partner
 * @body    FormData with 'images' field (multiple)
 */
router.post(
  "/establishments/:id/gallery",
  galleryUpload,
  uploadController.uploadGallery,
);

/**
 * @route   DELETE /api/v1/partner/establishments/:id/gallery
 * @desc    Delete gallery image
 * @access  Partner
 * @body    { image_url: "url" }
 */
router.delete(
  "/establishments/:id/gallery",
  uploadController.deleteGalleryImage,
);

/**
 * @route   PUT /api/v1/partner/establishments/:id/gallery/reorder
 * @desc    Reorder gallery images
 * @access  Partner
 * @body    { images: ["url1", "url2", ...] }
 */
router.put(
  "/establishments/:id/gallery/reorder",
  uploadController.reorderGallery,
);

// ==================== REVIEW ROUTES ====================

/**
 * @route   POST /api/v1/partner/reviews/:id/reply
 * @desc    Reply to a review
 * @access  Partner
 */
router.post(
  "/reviews/:id/reply",
  validate(reviewValidation.partnerReply),
  reviewController.partnerReply,
);

module.exports = router;
