const reviewService = require("../services/review.service");
const { ApiResponse } = require("../utils");

class ReviewController {
  // ==================== PUBLIC ROUTES ====================

  /**
   * Get establishment reviews
   * GET /api/v1/establishments/:establishmentId/reviews
   */
  async getEstablishmentReviews(req, res, next) {
    try {
      const { establishmentId } = req.params;
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        sort_by: req.query.sort_by,
        sort_order: req.query.sort_order,
      };

      const result = await reviewService.getEstablishmentReviews(
        establishmentId,
        options,
      );
      ApiResponse.success(result, "Reviews retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== USER ROUTES ====================

  /**
   * Get my reviews
   * GET /api/v1/reviews/me
   */
  async getMyReviews(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
      };

      const result = await reviewService.getUserReviews(req.userId, options);
      ApiResponse.success(result, "Reviews retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create review
   * POST /api/v1/establishments/:establishmentId/reviews
   */
  async createReview(req, res, next) {
    try {
      const { establishmentId } = req.params;
      const review = await reviewService.createReview(
        req.userId,
        establishmentId,
        req.body,
      );
      ApiResponse.created(
        review,
        "Review submitted successfully. Pending moderation.",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update review
   * PUT /api/v1/reviews/:id
   */
  async updateReview(req, res, next) {
    try {
      const review = await reviewService.updateReview(
        req.userId,
        req.params.id,
        req.body,
      );
      ApiResponse.success(
        review,
        "Review updated successfully. Pending moderation.",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete review
   * DELETE /api/v1/reviews/:id
   */
  async deleteReview(req, res, next) {
    try {
      const result = await reviewService.deleteReview(
        req.userId,
        req.params.id,
      );
      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Mark review as helpful
   * POST /api/v1/reviews/:id/helpful
   */
  async markHelpful(req, res, next) {
    try {
      const result = await reviewService.markHelpful(req.userId, req.params.id);
      ApiResponse.success(result, "Marked as helpful").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Report review
   * POST /api/v1/reviews/:id/report
   */
  async reportReview(req, res, next) {
    try {
      const { reason } = req.body;
      const result = await reviewService.reportReview(
        req.userId,
        req.params.id,
        reason,
      );
      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== PARTNER ROUTES ====================

  /**
   * Reply to review
   * POST /api/v1/partner/reviews/:id/reply
   */
  async partnerReply(req, res, next) {
    try {
      const { reply } = req.body;
      const review = await reviewService.partnerReply(
        req.partnerId,
        req.params.id,
        reply,
      );
      ApiResponse.success(review, "Reply added successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== ADMIN ROUTES ====================

  /**
   * Get all reviews with optional status filter
   * GET /api/v1/admin/reviews
   */
  async getAllReviews(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        status: req.query.status || 'all',
        search: req.query.search || null,
      };
      const result = await reviewService.getAllReviews(options);
      ApiResponse.success(result, 'Reviews retrieved successfully').send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Revoke an approved review back to pending
   * POST /api/v1/admin/reviews/:id/revoke
   */
  async revokeReview(req, res, next) {
    try {
      const review = await reviewService.revokeReview(req.params.id, req.userId);
      ApiResponse.success(review, 'Review revoked successfully').send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get pending reviews
   * GET /api/v1/admin/reviews/pending
   */
  async getPendingReviews(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
      };

      const result = await reviewService.getPendingReviews(options);
      ApiResponse.success(
        result,
        "Pending reviews retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get reported reviews
   * GET /api/v1/admin/reviews/reported
   */
  async getReportedReviews(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
      };

      const result = await reviewService.getReportedReviews(options);
      ApiResponse.success(
        result,
        "Reported reviews retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Approve review
   * POST /api/v1/admin/reviews/:id/approve
   */
  async approveReview(req, res, next) {
    try {
      const review = await reviewService.approveReview(
        req.params.id,
        req.userId,
      );
      ApiResponse.success(review, "Review approved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Reject review
   * POST /api/v1/admin/reviews/:id/reject
   */
  async rejectReview(req, res, next) {
    try {
      const { reason } = req.body;
      const review = await reviewService.rejectReview(
        req.params.id,
        req.userId,
        reason,
      );
      ApiResponse.success(review, "Review rejected").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Dismiss report
   * POST /api/v1/admin/reviews/:id/dismiss-report
   */
  async dismissReport(req, res, next) {
    try {
      const review = await reviewService.dismissReport(
        req.params.id,
        req.userId,
      );
      ApiResponse.success(review, "Report dismissed").send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReviewController();
