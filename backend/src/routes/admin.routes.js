const express = require("express");
const router = express.Router();
const adminController = require("../controllers/admin.controller");
const reviewController = require("../controllers/review.controller");
const suggestionController = require("../controllers/suggestion.controller");
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
 * @route   PATCH /api/v1/admin/users/:id/elite
 * @desc    Toggle elite status for a user
 * @access  Admin
 */
router.patch("/users/:id/elite", adminController.toggleEliteStatus);

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
 * @route   GET /api/v1/admin/establishments
 * @desc    Get all establishments with optional status filter
 * @access  Admin
 * @query   page, limit, status, search
 */
router.get("/establishments", adminController.getEstablishments);

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
 * @route   POST /api/v1/admin/establishments/:id/feature
 * @desc    Mettre en avant / retirer la mise en avant d'un établissement
 * @access  Admin
 * @body    { duration_days: number | null }  — 0 = retirer
 */
router.post("/establishments/:id/feature", adminController.setFeatured);

/**
 * @route   POST /api/v1/admin/establishments/:id/feature/checkout
 * @desc    Générer un lien Chargily pour mise à la une (paiement automatique)
 * @access  Admin
 * @body    { plan: "featured_7" | "featured_15" | "featured_30" }
 */
router.post("/establishments/:id/feature/checkout", adminController.featureCheckout);

/**
 * @route   POST /api/v1/admin/establishments/:id/feature/manual
 * @desc    Créer une facture manuelle pour mise à la une
 * @access  Admin
 * @body    { plan: "featured_7" | "featured_15" | "featured_30", transfer_reference?: string }
 */
router.post("/establishments/:id/feature/manual", adminController.featureManual);

/**
 * @route   PATCH /api/v1/admin/establishments/:id/assign-partner
 * @desc    Associate (or dissociate) a partner with an establishment
 * @access  Admin
 */
router.patch("/establishments/:id/assign-partner", adminController.assignPartner);

/**
 * @route   DELETE /api/v1/admin/establishments/:id
 * @desc    Delete establishment
 * @access  Admin
 */
router.delete("/establishments/:id", adminController.deleteEstablishment);

/**
 * @route   GET /api/v1/admin/establishments/:id
 * @desc    Get single establishment by id
 * @access  Admin
 */
router.get("/establishments/:id", adminController.getEstablishmentById);

/**
 * @route   PATCH /api/v1/admin/establishments/:id
 * @desc    Update establishment fields
 * @access  Admin
 */
router.patch("/establishments/:id", adminController.updateEstablishment);

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
router.post("/payments/:invoiceId/cancel", adminController.cancelPayment);

// ==================== REVIEW ROUTES ====================

/**
 * @route   GET /api/v1/admin/reviews
 * @desc    Get all reviews (filterable by status)
 * @access  Admin
 */
router.get("/reviews", reviewController.getAllReviews);

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
router.post("/reviews/:id/revoke", reviewController.revokeReview);

// ==================== WILAYA AVAILABILITY ====================

router.get("/wilayas", adminController.getAdminWilayas);
router.patch("/wilayas/:id/toggle", adminController.toggleWilayaAvailability);

// ==================== CATEGORY AVAILABILITY ====================

router.get("/categories", adminController.getAdminCategories);
router.patch("/categories/:id/toggle", adminController.toggleCategoryAvailability);

// ==================== SUGGESTION ROUTES ====================

/**
 * @route   GET /api/v1/admin/suggestions
 * @desc    Liste de toutes les suggestions (filtre par status optionnel)
 * @access  Admin
 */
router.get("/suggestions", suggestionController.adminGetAll);

/**
 * @route   POST /api/v1/admin/suggestions/:id/approve
 * @desc    Approuver une suggestion
 * @access  Admin
 */
router.post("/suggestions/:id/approve", suggestionController.adminApprove);

/**
 * @route   POST /api/v1/admin/suggestions/:id/reject
 * @desc    Rejeter une suggestion
 * @access  Admin
 */
router.post("/suggestions/:id/reject", suggestionController.adminReject);

module.exports = router;
