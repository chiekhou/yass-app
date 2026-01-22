const { User, Partner, Establishment, Review } = require("../models");
const ApiError = require("../utils/ApiError");
const { Op } = require("sequelize");
const emailService = require("./email.service");

class AdminService {
  /**
   * Get dashboard statistics
   */
  async getDashboardStats() {
    const [
      totalUsers,
      totalPartners,
      pendingPartners,
      totalEstablishments,
      activeEstablishments,
      pendingEstablishments,
      totalReviews,
    ] = await Promise.all([
      User.count({ where: { role: "user" } }),
      Partner.count(),
      Partner.count({ where: { status: "pending" } }),
      Establishment.count(),
      Establishment.count({ where: { status: "active" } }),
      Establishment.count({ where: { status: "pending" } }),
      Review.count(),
    ]);

    return {
      users: {
        total: totalUsers,
      },
      partners: {
        total: totalPartners,
        pending: pendingPartners,
      },
      establishments: {
        total: totalEstablishments,
        active: activeEstablishments,
        pending: pendingEstablishments,
      },
      reviews: {
        total: totalReviews,
      },
    };
  }

  // ==================== USER MANAGEMENT ====================

  /**
   * Get all users with pagination
   */
  async getUsers(options = {}) {
    const { page = 1, limit = 20, role, status, search } = options;
    const offset = (page - 1) * limit;

    const where = {};

    if (role) {
      where.role = role;
    }

    if (status) {
      where.status = status;
    }

    if (search) {
      where[Op.or] = [
        { email: { [Op.iLike]: `%${search}%` } },
        { first_name: { [Op.iLike]: `%${search}%` } },
        { last_name: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await User.findAndCountAll({
      where,
      limit,
      offset,
      order: [["created_at", "DESC"]],
      attributes: {
        exclude: [
          "password",
          "email_verification_token",
          "password_reset_token",
        ],
      },
      include: [
        {
          model: Partner,
          as: "partner_profile",
          required: false,
        },
      ],
    });

    return {
      users: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Get user by ID
   */
  async getUserById(userId) {
    const user = await User.findByPk(userId, {
      attributes: {
        exclude: [
          "password",
          "email_verification_token",
          "password_reset_token",
        ],
      },
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

    return user;
  }

  /**
   * Update user status
   */
  async updateUserStatus(userId, status, adminId) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    // Prevent modifying super_admin
    if (user.role === "super_admin") {
      throw ApiError.forbidden("Cannot modify super admin");
    }

    await user.update({ status });

    return user;
  }

  /**
   * Delete user
   */
  async deleteUser(userId, adminId) {
    const user = await User.findByPk(userId);

    if (!user) {
      throw ApiError.notFound("User not found");
    }

    // Prevent deleting super_admin
    if (user.role === "super_admin") {
      throw ApiError.forbidden("Cannot delete super admin");
    }

    await user.destroy();

    return { message: "User deleted successfully" };
  }

  // ==================== PARTNER MANAGEMENT ====================

  /**
   * Get all partners with pagination
   */
  async getPartners(options = {}) {
    const { page = 1, limit = 20, status, search } = options;
    const offset = (page - 1) * limit;

    const where = {};

    if (status) {
      where.status = status;
    }

    const userWhere = {};
    if (search) {
      userWhere[Op.or] = [
        { email: { [Op.iLike]: `%${search}%` } },
        { first_name: { [Op.iLike]: `%${search}%` } },
        { last_name: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await Partner.findAndCountAll({
      where,
      limit,
      offset,
      order: [["created_at", "DESC"]],
      include: [
        {
          model: User,
          as: "user",
          where: Object.keys(userWhere).length > 0 ? userWhere : undefined,
          attributes: [
            "id",
            "email",
            "first_name",
            "last_name",
            "phone",
            "status",
            "created_at",
          ],
        },
      ],
    });

    return {
      partners: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Get pending partners
   */
  async getPendingPartners(options = {}) {
    return this.getPartners({ ...options, status: "pending" });
  }

  /**
   * Get partner by ID
   */
  async getPartnerById(partnerId) {
    const partner = await Partner.findByPk(partnerId, {
      include: [
        {
          model: User,
          as: "user",
          attributes: {
            exclude: [
              "password",
              "email_verification_token",
              "password_reset_token",
            ],
          },
        },
        {
          model: Establishment,
          as: "establishments",
        },
      ],
    });

    if (!partner) {
      throw ApiError.notFound("Partner not found");
    }

    return partner;
  }

  /**
   * Approve partner
   */
  async approvePartner(partnerId, adminId) {
    const partner = await Partner.findByPk(partnerId, {
      include: [
        {
          model: User,
          as: "user",
        },
      ],
    });

    if (!partner) {
      throw ApiError.notFound("Partner not found");
    }

    if (partner.status === "approved") {
      throw ApiError.badRequest("Partner is already approved");
    }

    // Update partner status
    await partner.update({
      status: "approved",
      verified_at: new Date(),
      verified_by: adminId,
    });

    // Update user status to active
    await partner.user.update({ status: "active" });

    // Send approval email
    await emailService.sendPartnerApprovedEmail(partner.user, partner);

    return partner;
  }

  /**
   * Reject partner
   */
  async rejectPartner(partnerId, reason, adminId) {
    const partner = await Partner.findByPk(partnerId, {
      include: [
        {
          model: User,
          as: "user",
        },
      ],
    });

    if (!partner) {
      throw ApiError.notFound("Partner not found");
    }

    // Update partner status
    await partner.update({
      status: "rejected",
      rejection_reason: reason,
      verified_by: adminId,
    });

    // Update user status
    await partner.user.update({ status: "inactive" });

    // Send rejection email
    await emailService.sendPartnerRejectedEmail(partner.user, partner, reason);

    return partner;
  }

  /**
   * Suspend partner
   */
  async suspendPartner(partnerId, reason, adminId) {
    const partner = await Partner.findByPk(partnerId, {
      include: [
        {
          model: User,
          as: "user",
        },
      ],
    });

    if (!partner) {
      throw ApiError.notFound("Partner not found");
    }

    // Update partner status
    await partner.update({
      status: "suspended",
      notes: reason,
    });

    // Update user status
    await partner.user.update({ status: "suspended" });

    // Deactivate all establishments
    await Establishment.update(
      { status: "inactive" },
      { where: { partner_id: partnerId } },
    );

    return partner;
  }

  // ==================== ESTABLISHMENT MANAGEMENT ====================

  /**
   * Get pending establishments
   */
  async getPendingEstablishments(options = {}) {
    const { page = 1, limit = 20 } = options;
    const offset = (page - 1) * limit;

    const { count, rows } = await Establishment.findAndCountAll({
      where: { status: "pending" },
      limit,
      offset,
      order: [["created_at", "DESC"]],
      include: [
        {
          model: Partner,
          as: "partner",
          include: [
            {
              model: User,
              as: "user",
              attributes: ["id", "email", "first_name", "last_name"],
            },
          ],
        },
        { association: "category", attributes: ["id", "name", "name_ar"] },
        { association: "wilaya", attributes: ["id", "name", "name_ar"] },
      ],
    });

    return {
      establishments: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Approve establishment
   */
  async approveEstablishment(establishmentId, adminId) {
    const establishment = await Establishment.findByPk(establishmentId);

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    await establishment.update({
      status: "active",
      is_verified: true,
      verified_at: new Date(),
      verified_by: adminId,
    });

    return establishment;
  }

  /**
   * Reject establishment
   */
  async rejectEstablishment(establishmentId, reason, adminId) {
    const establishment = await Establishment.findByPk(establishmentId);

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    await establishment.update({
      status: "rejected",
      rejection_reason: reason,
      verified_by: adminId,
    });

    return establishment;
  }
}

module.exports = new AdminService();
