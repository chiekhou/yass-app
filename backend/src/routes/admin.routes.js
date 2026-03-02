const express = require("express");
const router = express.Router();
const adminController = require("../controllers/admin.controller");
const reviewController = require("../controllers/review.controller");
const { authenticate, isAdmin } = require("../middlewares/auth");
const validate = require("../middlewares/validate");
const adminValidation = require("../validations/admin.validation");
const reviewValidation = require("../validations/review.validation");

// All admin routes require authentication and admin role
router.use(authenticate);
router.use(isAdmin);

/**
 * @route   GET /api/v1/admin/dashboard
 * @desc    Get dashboard statistics
 * @access  Admin
 */
router.get("/dashboard", adminController.getDashboard);

// ==================== USER ROUTES ====================

/**
 * @route   GET /api/v1/admin/users
 * @desc    Get all users with pagination
 * @access  Admin
 * @query   page, limit, role, status, search
 */
router.get("/users", adminController.getUsers);

/**
 * @route   GET /api/v1/admin/users/:id
 * @desc    Get user by ID
 * @access  Admin
 */
router.get("/users/:id", adminController.getUserById);

/**
 * @route   PATCH /api/v1/admin/users/:id/status
 * @desc    Update user status
 * @access  Admin
 */
router.patch(
  "/users/:id/status",
  validate(adminValidation.updateUserStatus),
  adminController.updateUserStatus,
);

/**
 * @route   DELETE /api/v1/admin/users/:id
 * @desc    Delete user
 * @access  Admin
 */
router.delete("/users/:id", adminController.deleteUser);

// ==================== PARTNER ROUTES ====================

/**
 * @route   POST /api/v1/admin/partners
 * @desc    Create a new partner (admin-driven, auto-approved)
 * @access  Admin
 */
router.post(
  "/partners",
  validate(adminValidation.createPartner),
  adminController.createPartner,
);

/**
 * @route   GET /api/v1/admin/partners
 * @desc    Get all partners with pagination
 * @access  Admin
 * @query   page, limit, status, search
 */
router.get("/partners", adminController.getPartners);

/**
 * @route   GET /api/v1/admin/partners/pending
 * @desc    Get pending partners
 * @access  Admin
 */
router.get("/partners/pending", adminController.getPendingPartners);

/**
 * @route   GET /api/v1/admin/partners/:id
 * @desc    Get partner by ID
 * @access  Admin
 */
router.get("/partners/:id", adminController.getPartnerById);

/**
 * @route   POST /api/v1/admin/partners/:id/approve
 * @desc    Approve partner
 * @access  Admin
 */
router.post("/partners/:id/approve", adminController.approvePartner);

/**
 * @route   POST /api/v1/admin/partners/:id/reject
 * @desc    Reject partner
 * @access  Admin
 */
router.post(
  "/partners/:id/reject",
  validate(adminValidation.rejectPartner),
  adminController.rejectPartner,
);

/**
 * @route   POST /api/v1/admin/partners/:id/suspend
 * @desc    Suspend partner
 * @access  Admin
 */
router.post(
  "/partners/:id/suspend",
  validate(adminValidation.suspendPartner),
  adminController.suspendPartner,
);

// ==================== ESTABLISHMENT ROUTES ====================

/**
 * @route   POST /api/v1/admin/establishments
 * @desc    Create a new establishment (admin-driven, auto-approved)
 * @access  Admin
 */
router.post(
  "/establishments",
  validate(adminValidation.createEstablishment),
  adminController.createEstablishment,
);

/**
 * @route   GET /api/v1/admin/establishments/pending
 * @desc    Get pending establishments
 * @access  Admin
 */
router.get("/establishments/pending", adminController.getPendingEstablishments);

/**
 * @route   POST /api/v1/admin/establishments/:id/approve
 * @desc    Approve establishment
 * @access  Admin
 */
router.post(
  "/establishments/:id/approve",
  adminController.approveEstablishment,
);

/**
 * @route   POST /api/v1/admin/establishments/:id/reject
 * @desc    Reject establishment
 * @access  Admin
 */
router.post(
  "/establishments/:id/reject",
  validate(adminValidation.rejectEstablishment),
  adminController.rejectEstablishment,
);

/**
 * @route   DELETE /api/v1/admin/establishments/:id
 * @desc    Delete establishment
 * @access  Admin
 */
router.delete("/establishments/:id", adminController.deleteEstablishment);

// ==================== PAYMENT ROUTES ====================

/**
 * @route   GET /api/v1/admin/payments/pending
 * @desc    Liste des paiements manuels en attente de validation
 * @access  Admin
 */
router.get("/payments/pending", adminController.getPendingPayments);

/**
 * @route   POST /api/v1/admin/payments/:invoiceId/validate
 * @desc    Valider un paiement manuel et activer l'abonnement
 * @access  Admin
 */
router.post("/payments/:invoiceId/validate", adminController.validatePayment);

// ==================== REVIEW ROUTES ====================

/**
 * @route   GET /api/v1/admin/reviews/pending
 * @desc    Get pending reviews
 * @access  Admin
 */
router.get("/reviews/pending", reviewController.getPendingReviews);

/**
 * @route   GET /api/v1/admin/reviews/reported
 * @desc    Get reported reviews
 * @access  Admin
 */
router.get("/reviews/reported", reviewController.getReportedReviews);

/**
 * @route   POST /api/v1/admin/reviews/:id/approve
 * @desc    Approve review
 * @access  Admin
 */
router.post("/reviews/:id/approve", reviewController.approveReview);

/**
 * @route   POST /api/v1/admin/reviews/:id/reject
 * @desc    Reject review
 * @access  Admin
 */
router.post(
  "/reviews/:id/reject",
  validate(reviewValidation.rejectReview),
  reviewController.rejectReview,
);

/**
 * @route   POST /api/v1/admin/reviews/:id/dismiss-report
 * @desc    Dismiss review report
 * @access  Admin
 */
router.post("/reviews/:id/dismiss-report", reviewController.dismissReport);

module.exports = router;
