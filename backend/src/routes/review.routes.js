const express = require("express");
const router = express.Router();
const reviewController = require("../controllers/review.controller");
const { authenticate } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const { reviewValidation } = require("../validations");

/**
 * @route   GET /api/v1/reviews/me
 * @desc    Get my reviews
 * @access  Private
 */
router.get("/me", authenticate, reviewController.getMyReviews);

/**
 * @route   PUT /api/v1/reviews/:id
 * @desc    Update my review
 * @access  Private
 */
router.put(
  "/:id",
  authenticate,
  validate(reviewValidation.updateReview),
  reviewController.updateReview,
);

/**
 * @route   DELETE /api/v1/reviews/:id
 * @desc    Delete my review
 * @access  Private
 */
router.delete("/:id", authenticate, reviewController.deleteReview);

/**
 * @route   POST /api/v1/reviews/:id/helpful
 * @desc    Mark review as helpful
 * @access  Private
 */
router.post("/:id/helpful", authenticate, reviewController.markHelpful);

/**
 * @route   POST /api/v1/reviews/:id/report
 * @desc    Report a review
 * @access  Private
 */
router.post(
  "/:id/report",
  authenticate,
  validate(reviewValidation.reportReview),
  reviewController.reportReview,
);

module.exports = router;
