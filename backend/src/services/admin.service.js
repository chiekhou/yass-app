const { User, Partner, Establishment, Review, Favorite, Promotion, RefreshToken, SubCategory, Commune, AppSession } = require("../models");
const invoiceService = require("./invoice.service");
const ApiError = require("../utils/ApiError");
const { Op, literal } = require("sequelize");
const emailService = require("./email.service");
const { generateSlug, generateUniqueSlug } = require("../utils/helpers");
const notificationService = require("./notification.service");

class AdminService {
  /**
   * Get dashboard statistics
   */
  async getDashboardStats() {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(startOfToday);
    startOfWeek.setDate(startOfToday.getDate() - startOfToday.getDay());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      totalUsers,
      totalPartners,
      pendingPartners,
      totalEstablishments,
      activeEstablishments,
      pendingEstablishments,
      totalReviews,
      pendingReviews,
      reportedReviews,
      totalVisits,
      visitsToday,
      visitsThisWeek,
      visitsThisMonth,
      genderMale,
      genderFemale,
      genderYoung,
      genderChild,
      genderUnknown,
      ageUnder18,
      age18to25,
      age26to35,
      age36to50,
      ageOver50,
      ageUnknown,
    ] = await Promise.all([
      User.count({ where: { role: "user" } }),
      Partner.count(),
      Partner.count({ where: { status: "pending" } }),
      Establishment.count(),
      Establishment.count({ where: { status: "active" } }),
      Establishment.count({ where: { status: "pending" } }),
      Review.count(),
      Review.count({ where: { status: "pending" } }),
      Review.count({ where: { report_count: { [Op.gt]: 0 } } }),
      AppSession.count(),
      AppSession.count({ where: { created_at: { [Op.gte]: startOfToday } } }),
      AppSession.count({ where: { created_at: { [Op.gte]: startOfWeek } } }),
      AppSession.count({ where: { created_at: { [Op.gte]: startOfMonth } } }),
      User.count({ where: { role: "user", gender: "male" } }),
      User.count({ where: { role: "user", gender: "female" } }),
      User.count({ where: { role: "user", gender: "young" } }),
      User.count({ where: { role: "user", gender: "child" } }),
      User.count({ where: { role: "user", gender: null } }),
      User.count({ where: { role: "user", age: { [Op.lt]: 18, [Op.not]: null } } }),
      User.count({ where: { role: "user", age: { [Op.between]: [18, 25] } } }),
      User.count({ where: { role: "user", age: { [Op.between]: [26, 35] } } }),
      User.count({ where: { role: "user", age: { [Op.between]: [36, 50] } } }),
      User.count({ where: { role: "user", age: { [Op.gt]: 50 } } }),
      User.count({ where: { role: "user", age: null } }),
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
        pending: pendingReviews,
        reported: reportedReviews,
      },
      demographics: {
        male: genderMale,
        female: genderFemale,
        young: genderYoung,
        child: genderChild,
        unknown: genderUnknown,
        age_under_18: ageUnder18,
        age_18_25: age18to25,
        age_26_35: age26to35,
        age_36_50: age36to50,
        age_over_50: ageOver50,
        age_unknown: ageUnknown,
      },
      visits: {
        total: totalVisits,
        today: visitsToday,
        this_week: visitsThisWeek,
        this_month: visitsThisMonth,
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

    // Delete refresh tokens
    await RefreshToken.destroy({ where: { user_id: userId } });

    // If user is a partner, delete establishments and their dependencies first
    const partner = await Partner.findOne({ where: { user_id: userId } });
    if (partner) {
      const establishments = await Establishment.findAll({
        where: { partner_id: partner.id },
        attributes: ["id"],
      });
      const establishmentIds = establishments.map((e) => e.id);
      if (establishmentIds.length > 0) {
        await Promotion.destroy({ where: { establishment_id: establishmentIds } });
        await Favorite.destroy({ where: { establishment_id: establishmentIds } });
        await Review.destroy({ where: { establishment_id: establishmentIds } });
        await Establishment.destroy({ where: { partner_id: partner.id } });
      }
      await partner.destroy();
    }

    // Delete user's own favorites and reviews (on other establishments)
    await Favorite.destroy({ where: { user_id: userId } });
    await Review.destroy({ where: { user_id: userId } });

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
      attributes: {
        include: [
          [
            literal(
              '(SELECT COUNT(*) FROM establishments WHERE establishments.partner_id = "Partner"."id")',
            ),
            "establishments_count",
          ],
        ],
      },
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
      distinct: true,
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

    // Update partner status and start 14-day trial
    const trialEndsAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000);
    await partner.update({
      status: "approved",
      verified_at: new Date(),
      verified_by: adminId,
      trial_ends_at: trialEndsAt,
    });

    // Update user status to active
    await partner.user.update({ status: "active" });

    // Send approval email
    await emailService.sendPartnerApprovedEmail(partner.user, partner);

    // Send in-app + push notification
    notificationService.notifyPartnerApproved(partner, partner.user.id).catch(() => {});

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

    // Send in-app + push notification
    notificationService.notifyPartnerRejected(partner, partner.user.id, reason).catch(() => {});

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

  /**
   * Create partner (admin-driven, auto-approved)
   * POST /api/v1/admin/partners
   */
  async createPartner(data, adminId) {
    const {
      email, password, first_name, last_name, phone,
      language, wilaya_id,
      company_name, registration_number, tax_id,
    } = data;

    // Check email uniqueness
    const existing = await User.findOne({ where: { email } });
    if (existing) {
      throw ApiError.conflict("A user with this email already exists");
    }

    // Create user with role=partner, active + verified (no OTP needed)
    // Note: User model's beforeCreate hook handles password hashing automatically
    const user = await User.create({
      email,
      password,
      first_name,
      last_name,
      phone: phone || null,
      role: "partner",
      status: "active",
      language: language || "fr",
      email_verified: true,
      wilaya_id: wilaya_id || null,
    });

    // Create partner, already approved
    const partner = await Partner.create({
      user_id: user.id,
      company_name,
      registration_number: registration_number || null,
      tax_id: tax_id || null,
      status: "approved",
      subscription_plan: "free",
      verified_at: new Date(),
      verified_by: adminId,
    });

    return Partner.findByPk(partner.id, {
      include: [
        {
          model: User,
          as: "user",
          attributes: { exclude: ["password", "email_verification_token", "password_reset_token"] },
        },
      ],
    });
  }

  /**
   * Create establishment for a partner (admin-driven, auto-approved)
   * POST /api/v1/admin/establishments
   */
  async createEstablishment(data, adminId) {
    const { partner_id, subcategory_id, commune_id } = data;

    // Verify partner exists and is approved
    const partner = await Partner.findByPk(partner_id);
    if (!partner) {
      throw ApiError.notFound("Partner not found");
    }
    if (partner.status !== "approved") {
      throw ApiError.badRequest("Partner must be approved to create an establishment");
    }

    // Resolve subcategory → category_id
    const subcategory = await SubCategory.findByPk(subcategory_id);
    if (!subcategory) {
      throw ApiError.badRequest("Subcategory not found");
    }

    // Resolve commune → wilaya_id
    const commune = await Commune.findByPk(commune_id);
    if (!commune) {
      throw ApiError.badRequest("Commune not found");
    }

    // Generate unique slug
    const slug = await generateUniqueSlug(Establishment, generateSlug(data.name));

    const establishment = await Establishment.create({
      partner_id,
      category_id: subcategory.category_id,
      subcategory_id,
      wilaya_id: commune.wilaya_id,
      commune_id,
      name: data.name,
      name_ar: data.name_ar || null,
      slug,
      description: data.description,
      description_ar: data.description_ar || null,
      address: data.address,
      address_ar: data.address_ar || null,
      latitude: data.latitude || null,
      longitude: data.longitude || null,
      phone: data.phone || null,
      whatsapp: data.whatsapp || null,
      email: data.email || null,
      website: data.website || null,
      logo: data.logo || null,
      cover_image: data.cover_image || null,
      images: JSON.stringify(data.images || []),
      opening_hours: JSON.stringify(data.opening_hours || {}),
      price_range: data.price_range || null,
      services: JSON.stringify(data.services || []),
      amenities: JSON.stringify(data.amenities || []),
      tags: JSON.stringify(data.tags || []),
      status: "active",
      is_verified: true,
      is_featured: false,
      verified_at: new Date(),
      verified_by: adminId,
    });

    return establishment;
  }

  // ==================== ESTABLISHMENT MANAGEMENT ====================

  /**
   * Get all establishments with optional status filter and search
   */
  async getEstablishments(options = {}) {
    const { page = 1, limit = 20, status, search } = options;
    const offset = (page - 1) * limit;

    const where = {};
    if (status) where.status = status;
    if (search) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { address: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows } = await Establishment.findAndCountAll({
      where,
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
      distinct: true,
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

    // Charger le partenaire pour vérifier l'abonnement Gold
    const partner = await Partner.findByPk(establishment.partner_id, {
      attributes: ["user_id", "subscription_plan", "subscription_expires_at"],
    });

    const now = new Date();
    const hasGold =
      partner?.subscription_plan === "gold" &&
      partner.subscription_expires_at != null &&
      new Date(partner.subscription_expires_at) > now;

    await establishment.update({
      status: "active",
      is_verified: true,
      verified_at: new Date(),
      verified_by: adminId,
      // Si le partenaire a Gold actif, mise à la une automatique
      ...(hasGold && {
        is_featured: true,
        featured_until: partner.subscription_expires_at,
      }),
    });

    // Notify partner
    if (partner) {
      notificationService.notifyEstablishmentApproved(establishment, partner.user_id).catch(() => {});
    }

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

    // Notify partner
    const partner = await Partner.findByPk(establishment.partner_id, { attributes: ["user_id"] });
    if (partner) {
      notificationService.notifyEstablishmentRejected(establishment, partner.user_id, reason).catch(() => {});
    }

    return establishment;
  }

  // ==================== PAYMENT MANAGEMENT ====================

  /**
   * Get pending manual payments
   */
  async getPendingManualPayments(options = {}) {
    return invoiceService.getPendingManualPayments(options);
  }

  /**
   * Validate a manual payment and activate the partner's subscription
   */
  async validateManualPayment(invoiceId, adminId) {
    return invoiceService.validateManualPayment(invoiceId, adminId);
  }

  // ==================== ESTABLISHMENT MANAGEMENT ====================

  /**
   * Delete establishment (admin)
   */
  async deleteEstablishment(establishmentId) {
    const establishment = await Establishment.findByPk(establishmentId);

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    await Promotion.destroy({ where: { establishment_id: establishmentId } });
    await Favorite.destroy({ where: { establishment_id: establishmentId } });
    await Review.destroy({ where: { establishment_id: establishmentId } });
    await establishment.destroy();
  }

  /**
   * Toggle featured status of an establishment.
   * durationDays = null → sans limite (featured_until = null)
   * durationDays = 0    → retirer la mise en avant
   * durationDays > 0    → mettre en avant pour N jours
   */
  /**
   * Assign (or unassign) a partner to an unowned establishment.
   * partnerId = null → détacher le partenaire
   */
  async assignPartner(establishmentId, partnerId) {
    const establishment = await Establishment.findByPk(establishmentId);
    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    if (partnerId) {
      const partner = await Partner.findByPk(partnerId);
      if (!partner) {
        throw ApiError.notFound("Partner not found");
      }
    }

    await establishment.update({ partner_id: partnerId || null });
    return establishment.reload();
  }

  async setFeatured(establishmentId, durationDays) {
    const establishment = await Establishment.findByPk(establishmentId);
    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    if (durationDays !== 0 && establishment.status !== "active") {
      throw ApiError.badRequest("Seuls les établissements actifs peuvent être mis à la une");
    }

    if (durationDays === 0) {
      await establishment.update({ is_featured: false, featured_until: null });
    } else if (durationDays == null) {
      await establishment.update({ is_featured: true, featured_until: null });
    } else {
      const until = new Date();
      until.setDate(until.getDate() + parseInt(durationDays));
      await establishment.update({ is_featured: true, featured_until: until });
    }

    return establishment.reload();
  }
}

module.exports = new AdminService();
