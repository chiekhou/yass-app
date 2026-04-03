const { Review, Establishment, User, Partner } = require("../models");
const ApiError = require("../utils/ApiError");
const { Op } = require("sequelize");
const sequelize = require("../models").sequelize;

class ReviewService {
  /**
   * Get reviews for an establishment (public)
   */
  async getEstablishmentReviews(establishmentId, options = {}) {
    const {
      page = 1,
      limit = 20,
      sort_by = "created_at",
      sort_order = "DESC",
    } = options;
    const offset = (page - 1) * limit;

    // Verify establishment exists
    const establishment = await Establishment.findByPk(establishmentId);
    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // Valid sort fields
    const validSortFields = ["created_at", "rating", "helpful_count"];
    const orderField = validSortFields.includes(sort_by)
      ? sort_by
      : "created_at";
    const orderDirection = sort_order.toUpperCase() === "ASC" ? "ASC" : "DESC";

    const { count, rows } = await Review.findAndCountAll({
      where: {
        establishment_id: establishmentId,
        status: "approved",
      },
      include: [
        {
          model: User,
          as: "user",
          attributes: ["id", "first_name", "last_name", "avatar"],
        },
      ],
      order: [[orderField, orderDirection]],
      limit,
      offset,
    });

    // Calculate rating distribution
    const ratingDistribution = await Review.findAll({
      where: {
        establishment_id: establishmentId,
        status: "approved",
      },
      attributes: [
        "rating",
        [sequelize.fn("COUNT", sequelize.col("rating")), "count"],
      ],
      group: ["rating"],
      raw: true,
    });

    const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    ratingDistribution.forEach((r) => {
      distribution[r.rating] = parseInt(r.count);
    });

    return {
      reviews: rows,
      rating_distribution: distribution,
      average_rating: establishment.average_rating,
      total_reviews: count,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Get user's reviews
   */
  async getUserReviews(userId, options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    const { count, rows } = await Review.findAndCountAll({
      where: { user_id: userId },
      include: [
        {
          model: Establishment,
          as: "establishment",
          attributes: [
            "id",
            "name",
            "name_ar",
            "slug",
            "logo",
            "average_rating",
          ],
        },
      ],
      order: [["created_at", "DESC"]],
      limit,
      offset,
    });

    return {
      reviews: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Create a review
   */
  async createReview(userId, establishmentId, data) {
    // Verify establishment exists and is active
    const establishment = await Establishment.findOne({
      where: { id: establishmentId, status: "active" },
      include: [{ model: require("../models").Partner, as: "partner", attributes: ["subscription_plan", "subscription_expires_at"] }],
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // Vérifier que le partenaire a un abonnement Premium ou Gold actif
    const partner = establishment.partner;
    const now = new Date();
    const isPremiumOrAbove =
      partner &&
      ["premium", "gold"].includes(partner.subscription_plan) &&
      partner.subscription_expires_at != null &&
      new Date(partner.subscription_expires_at) > now;

    if (!isPremiumOrAbove) {
      throw ApiError.forbidden("Les avis ne sont disponibles que pour les établissements Premium ou Gold.");
    }

    // Check if user already reviewed this establishment
    const existingReview = await Review.findOne({
      where: { user_id: userId, establishment_id: establishmentId },
    });

    if (existingReview) {
      throw ApiError.badRequest("You have already reviewed this establishment");
    }

    // Compute global rating from sub_ratings if provided
    let globalRating = data.rating;
    if (data.sub_ratings && typeof data.sub_ratings === "object") {
      const values = Object.values(data.sub_ratings).filter(
        (v) => Number.isInteger(v) && v >= 1 && v <= 5
      );
      if (values.length > 0) {
        globalRating = Math.round(values.reduce((a, b) => a + b, 0) / values.length);
      }
    }

    // Create review
    const review = await Review.create({
      user_id: userId,
      establishment_id: establishmentId,
      rating: globalRating,
      title: data.title,
      comment: data.comment,
      pros: data.pros || [],
      cons: data.cons || [],
      images: data.images || [],
      visit_date: data.visit_date,
      sub_ratings: data.sub_ratings || null,
      status: "pending", // Requires moderation
    });

    // Load review with user
    const createdReview = await Review.findByPk(review.id, {
      include: [
        {
          model: User,
          as: "user",
          attributes: ["id", "first_name", "last_name", "avatar"],
        },
      ],
    });

    return createdReview;
  }

  /**
   * Update a review
   */
  async updateReview(userId, reviewId, data) {
    const review = await Review.findOne({
      where: { id: reviewId, user_id: userId },
    });

    if (!review) {
      throw ApiError.notFound("Review not found");
    }

    // Update review
    await review.update({
      rating: data.rating !== undefined ? data.rating : review.rating,
      title: data.title !== undefined ? data.title : review.title,
      comment: data.comment !== undefined ? data.comment : review.comment,
      pros: data.pros !== undefined ? data.pros : review.pros,
      cons: data.cons !== undefined ? data.cons : review.cons,
      images: data.images !== undefined ? data.images : review.images,
      visit_date:
        data.visit_date !== undefined ? data.visit_date : review.visit_date,
      status: "pending", // Re-submit for moderation after edit
    });

    // Recalculate establishment rating
    await this.recalculateEstablishmentRating(review.establishment_id);

    // Load updated review
    const updatedReview = await Review.findByPk(review.id, {
      include: [
        {
          model: User,
          as: "user",
          attributes: ["id", "first_name", "last_name", "avatar"],
        },
      ],
    });

    return updatedReview;
  }

  /**
   * Delete a review
   */
  async deleteReview(userId, reviewId) {
    const review = await Review.findOne({
      where: { id: reviewId, user_id: userId },
    });

    if (!review) {
      throw ApiError.notFound("Review not found");
    }

    const establishmentId = review.establishment_id;

    await review.destroy();

    // Recalculate establishment rating
    await this.recalculateEstablishmentRating(establishmentId);

    return { message: "Review deleted successfully" };
  }

  /**
   * Mark review as helpful
   */
  async markHelpful(userId, reviewId) {
    const review = await Review.findOne({
      where: { id: reviewId, status: "approved" },
    });

    if (!review) {
      throw ApiError.notFound("Review not found");
    }

    // Prevent user from marking their own review
    if (review.user_id === userId) {
      throw ApiError.badRequest("You cannot mark your own review as helpful");
    }

    // Increment helpful count
    await review.increment("helpful_count");

    return {
      helpful_count: review.helpful_count + 1,
    };
  }

  /**
   * Report a review
   */
  async reportReview(userId, reviewId, reason) {
    const review = await Review.findByPk(reviewId);

    if (!review) {
      throw ApiError.notFound("Review not found");
    }

    // Incrémenter le compteur de signalements
    await review.increment("report_count");

    return { message: "Review reported successfully" };
  }

  /**
   * Partner reply to review
   */
  async partnerReply(partnerId, reviewId, reply) {
    const review = await Review.findByPk(reviewId, {
      include: [
        {
          model: Establishment,
          as: "establishment",
          where: { partner_id: partnerId },
        },
      ],
    });

    if (!review) {
      throw ApiError.notFound("Review not found or not authorized");
    }

    await review.update({
      partner_reply: reply,
      partner_reply_at: new Date(),
    });

    return review;
  }

  // ==================== ADMIN METHODS ====================

  /**
   * Get pending reviews (admin)
   */
  async getPendingReviews(options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    const { count, rows } = await Review.findAndCountAll({
      where: { status: "pending" },
      include: [
        {
          model: User,
          as: "user",
          attributes: ["id", "first_name", "last_name", "email"],
        },
        {
          model: Establishment,
          as: "establishment",
          attributes: ["id", "name", "name_ar", "slug"],
        },
      ],
      order: [["created_at", "ASC"]],
      limit,
      offset,
    });

    return {
      reviews: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Get reported reviews (admin)
   */
  async getReportedReviews(options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    const { count, rows } = await Review.findAndCountAll({
      where: { report_count: { [Op.gt]: 0 } },
      include: [
        {
          model: User,
          as: "user",
          attributes: ["id", "first_name", "last_name", "email"],
        },
        {
          model: Establishment,
          as: "establishment",
          attributes: ["id", "name", "name_ar", "slug"],
        },
      ],
      order: [["created_at", "DESC"]],
      limit,
      offset,
    });

    return {
      reviews: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Get all reviews with optional status filter (admin)
   */
  async getAllReviews(options = {}) {
    const { page = 1, limit = 20, status, search } = options;
    const offset = (page - 1) * limit;

    const where = {};
    if (status && status !== 'all') where.status = status;
    if (search) {
      where[Op.or] = [
        { comment: { [Op.iLike]: `%${search}%` } },
        { title: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await Review.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: 'user',
          attributes: ['id', 'first_name', 'last_name', 'email', 'avatar'],
        },
        {
          model: Establishment,
          as: 'establishment',
          attributes: ['id', 'name', 'name_ar', 'slug'],
        },
      ],
      order: [['created_at', 'DESC']],
      limit,
      offset,
    });

    return {
      reviews: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Revoke an approved review back to pending (admin)
   */
  async revokeReview(reviewId, adminId) {
    const review = await Review.findByPk(reviewId);
    if (!review) throw ApiError.notFound('Review not found');
    if (review.status !== 'approved') {
      throw ApiError.badRequest('Seuls les avis approuvés peuvent être révoqués');
    }
    await review.update({ status: 'pending', moderated_by: adminId, moderated_at: new Date() });
    return review;
  }

  /**
   * Approve review (admin)
   */
  async approveReview(reviewId, adminId) {
    const review = await Review.findByPk(reviewId);

    if (!review) {
      throw ApiError.notFound("Review not found");
    }

    await review.update({
      status: "approved",
      moderated_by: adminId,
      moderated_at: new Date(),
    });

    // Recalculate establishment rating
    await this.recalculateEstablishmentRating(review.establishment_id);

    return review;
  }

  /**
   * Reject review (admin)
   */
  async rejectReview(reviewId, adminId, reason) {
    const review = await Review.findByPk(reviewId);

    if (!review) {
      throw ApiError.notFound("Review not found");
    }

    await review.update({
      status: "rejected",
      rejection_reason: reason,
      moderated_by: adminId,
      moderated_at: new Date(),
    });

    // Recalculate establishment rating (in case it was previously approved)
    await this.recalculateEstablishmentRating(review.establishment_id);

    return review;
  }

  /**
   * Dismiss report (admin)
   */
  async dismissReport(reviewId, adminId) {
    const review = await Review.findByPk(reviewId);

    if (!review) {
      throw ApiError.notFound("Review not found");
    }

    // Réinitialiser le compteur de signalements
    await review.update({ report_count: 0 });

    return review;
  }

  /**
   * Recalculate establishment rating
   */
  async recalculateEstablishmentRating(establishmentId) {
    const result = await Review.findOne({
      where: {
        establishment_id: establishmentId,
        status: "approved",
      },
      attributes: [
        [sequelize.fn("AVG", sequelize.col("rating")), "avg_rating"],
        [sequelize.fn("COUNT", sequelize.col("id")), "total_reviews"],
      ],
      raw: true,
    });

    const avgRating = result.avg_rating
      ? parseFloat(result.avg_rating).toFixed(2)
      : 0;
    const totalReviews = parseInt(result.total_reviews) || 0;

    await Establishment.update(
      {
        average_rating: avgRating,
        total_reviews: totalReviews,
      },
      { where: { id: establishmentId } },
    );

    return { average_rating: avgRating, total_reviews: totalReviews };
  }
}

module.exports = new ReviewService();
