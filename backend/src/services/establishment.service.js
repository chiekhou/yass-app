const {
  Establishment,
  Partner,
  Category,
  SubCategory,
  Wilaya,
  Commune,
  User,
  Review,
  Favorite,
} = require("../models");
const ApiError = require("../utils/ApiError");
const { generateSlug, generateUniqueSlug, calculateDistance } = require("../utils/helpers");
const { Op } = require("sequelize");

class EstablishmentService {
  /**
   * Default includes for establishment queries
   */
  getDefaultIncludes(options = {}) {
    const { includePartner = false, includeReviews = false } = options;

    const includes = [
      {
        model: Category,
        as: "category",
        attributes: ["id", "name", "name_ar", "slug", "icon", "color"],
      },
      {
        model: SubCategory,
        as: "subcategory",
        attributes: ["id", "name", "name_ar", "slug", "icon"],
      },
      {
        model: Wilaya,
        as: "wilaya",
        attributes: ["id", "code", "name", "name_ar"],
      },
      {
        model: Commune,
        as: "commune",
        attributes: ["id", "code", "name", "name_ar", "postal_code"],
      },
    ];

    if (includePartner) {
      includes.push({
        model: Partner,
        as: "partner",
        attributes: ["id", "company_name", "status"],
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "first_name", "last_name", "email", "phone"],
          },
        ],
      });
    }

    if (includeReviews) {
      includes.push({
        model: Review,
        as: "reviews",
        where: { status: "approved" },
        required: false,
        limit: 5,
        order: [["created_at", "DESC"]],
        include: [
          {
            model: User,
            as: "user",
            attributes: ["id", "first_name", "last_name", "avatar"],
          },
        ],
      });
    }

    return includes;
  }

  /**
   * Include filter: only establishments from partners with active subscription or trial
   */
  getSubscriptionInclude() {
    const now = new Date();
    return {
      model: Partner,
      as: "partner",
      attributes: [],
      required: true,
      where: {
        [Op.or]: [
          // Active paid subscription
          {
            subscription_plan: { [Op.ne]: "free" },
            subscription_expires_at: { [Op.gt]: now },
          },
          // Within 14-day trial
          {
            subscription_plan: "free",
            trial_ends_at: { [Op.gt]: now },
          },
        ],
      },
    };
  }

  /**
   * Public attributes (hide sensitive data)
   */
  getPublicAttributes() {
    return {
      exclude: ["verified_by", "rejection_reason"],
    };
  }

  // ==================== PUBLIC METHODS ====================

  /**
   * Search establishments with filters
   */
  async search(filters = {}) {
    const {
      q, // Search query
      category_id,
      subcategory_id,
      wilaya_id,
      commune_id,
      price_range,
      is_verified,
      is_featured,
      min_rating,
      latitude,
      longitude,
      radius, // in km
      services, // array of services
      amenities, // array of amenities
      tags, // array of tags
      sort_by = "created_at",
      sort_order = "DESC",
      page = 1,
      limit = 20,
    } = filters;

    const where = { status: "active" };
    const offset = (page - 1) * limit;

    // Text search
    if (q) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${q}%` } },
        { name_ar: { [Op.iLike]: `%${q}%` } },
        { description: { [Op.iLike]: `%${q}%` } },
        { address: { [Op.iLike]: `%${q}%` } },
      ];
    }

    // Category filters
    if (category_id) where.category_id = category_id;
    if (subcategory_id) where.subcategory_id = subcategory_id;

    // Location filters
    if (wilaya_id) where.wilaya_id = wilaya_id;
    if (commune_id) where.commune_id = commune_id;

    // Other filters
    if (price_range) where.price_range = price_range;
    if (is_verified !== undefined)
      where.is_verified = is_verified === "true" || is_verified === true;
    if (is_featured !== undefined)
      where.is_featured = is_featured === "true" || is_featured === true;
    if (min_rating) where.average_rating = { [Op.gte]: parseFloat(min_rating) };

    // JSON filters (services, amenities, tags)
    if (services && services.length > 0) {
      where.services = { [Op.contains]: services };
    }
    if (amenities && amenities.length > 0) {
      where.amenities = { [Op.contains]: amenities };
    }
    if (tags && tags.length > 0) {
      where.tags = { [Op.overlap]: tags };
    }

    // Sorting
    const validSortFields = [
      "created_at",
      "average_rating",
      "total_reviews",
      "total_views",
      "name",
    ];
    const orderField = validSortFields.includes(sort_by)
      ? sort_by
      : "created_at";
    const orderDirection = sort_order.toUpperCase() === "ASC" ? "ASC" : "DESC";

    // Build order array
    let order = [[orderField, orderDirection]];

    // If sorting by rating, also sort by reviews count
    if (orderField === "average_rating") {
      order.push(["total_reviews", "DESC"]);
    }

    const { count, rows } = await Establishment.findAndCountAll({
      where,
      include: [...this.getDefaultIncludes(), this.getSubscriptionInclude()],
      attributes: this.getPublicAttributes(),
      order,
      limit: Math.min(limit, 100),
      offset,
      distinct: true,
    });

    let results = rows;

    // Geo filtering (post-query for simplicity)
    if (latitude && longitude && radius) {
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);
      const maxRadius = parseFloat(radius);

      results = rows.filter((est) => {
        if (!est.latitude || !est.longitude) return false;
        const distance = calculateDistance(
          lat,
          lng,
          est.latitude,
          est.longitude,
        );
        est.dataValues.distance = Math.round(distance * 100) / 100; // Add distance to result
        return distance <= maxRadius;
      });

      // Sort by distance if geo filtering
      results.sort((a, b) => a.dataValues.distance - b.dataValues.distance);
    }

    return {
      establishments: results,
      pagination: {
        total: latitude && longitude && radius ? results.length : count,
        page,
        limit,
        totalPages: Math.ceil(
          (latitude && longitude && radius ? results.length : count) / limit,
        ),
      },
    };
  }

  /**
   * Get establishment by ID (public)
   */
  async getById(id, options = {}) {
    const { userId = null } = options;

    const establishment = await Establishment.findOne({
      where: { id, status: "active" },
      include: this.getDefaultIncludes({ includeReviews: true }),
      attributes: this.getPublicAttributes(),
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // Increment view count
    await establishment.increment("total_views");

    // Check if user has favorited
    let isFavorited = false;
    if (userId) {
      const favorite = await Favorite.findOne({
        where: { user_id: userId, establishment_id: id },
      });
      isFavorited = !!favorite;
    }

    return {
      ...establishment.toJSON(),
      is_favorited: isFavorited,
    };
  }

  /**
   * Get establishment by slug (public)
   */
  async getBySlug(slug, options = {}) {
    const { userId = null } = options;

    const establishment = await Establishment.findOne({
      where: { slug, status: "active" },
      include: this.getDefaultIncludes({ includeReviews: true }),
      attributes: this.getPublicAttributes(),
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // Increment view count
    await establishment.increment("total_views");

    // Check if user has favorited
    let isFavorited = false;
    if (userId) {
      const favorite = await Favorite.findOne({
        where: { user_id: userId, establishment_id: establishment.id },
      });
      isFavorited = !!favorite;
    }

    return {
      ...establishment.toJSON(),
      is_favorited: isFavorited,
    };
  }

  /**
   * Get featured establishments
   */
  async getFeatured(limit = 10) {
    const establishments = await Establishment.findAll({
      where: { status: "active", is_featured: true },
      include: [...this.getDefaultIncludes(), this.getSubscriptionInclude()],
      attributes: this.getPublicAttributes(),
      order: [
        ["average_rating", "DESC"],
        ["total_reviews", "DESC"],
      ],
      limit,
    });

    return establishments;
  }

  /**
   * Get nearby establishments
   */
  async getNearby(latitude, longitude, radius = 10, limit = 20) {
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const maxRadius = parseFloat(radius);

    // Get all active establishments with coordinates
    const establishments = await Establishment.findAll({
      where: {
        status: "active",
        latitude: { [Op.ne]: null },
        longitude: { [Op.ne]: null },
      },
      include: [...this.getDefaultIncludes(), this.getSubscriptionInclude()],
      attributes: this.getPublicAttributes(),
    });

    // Filter by distance and add distance field
    const nearby = establishments
      .map((est) => {
        const distance = calculateDistance(
          lat,
          lng,
          est.latitude,
          est.longitude,
        );
        return {
          ...est.toJSON(),
          distance: Math.round(distance * 100) / 100,
        };
      })
      .filter((est) => est.distance <= maxRadius)
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);

    return nearby;
  }

  /**
   * Get establishments by category
   */
  async getByCategory(categoryId, options = {}) {
    const { page = 1, limit = 20, wilaya_id } = options;
    const offset = (page - 1) * limit;

    const where = { status: "active", category_id: categoryId };
    if (wilaya_id) where.wilaya_id = wilaya_id;

    const { count, rows } = await Establishment.findAndCountAll({
      where,
      include: [...this.getDefaultIncludes(), this.getSubscriptionInclude()],
      attributes: this.getPublicAttributes(),
      order: [
        ["average_rating", "DESC"],
        ["total_reviews", "DESC"],
      ],
      limit,
      offset,
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
   * Get establishments by wilaya
   */
  async getByWilaya(wilayaId, options = {}) {
    const { page = 1, limit = 20, category_id } = options;
    const offset = (page - 1) * limit;

    const where = { status: "active", wilaya_id: wilayaId };
    if (category_id) where.category_id = category_id;

    const { count, rows } = await Establishment.findAndCountAll({
      where,
      include: [...this.getDefaultIncludes(), this.getSubscriptionInclude()],
      attributes: this.getPublicAttributes(),
      order: [
        ["average_rating", "DESC"],
        ["total_reviews", "DESC"],
      ],
      limit,
      offset,
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
   * Track phone click
   */
  async trackPhoneClick(establishmentId) {
    const establishment = await Establishment.findByPk(establishmentId);
    if (establishment) {
      await establishment.increment("total_calls");
    }
  }

  /**
   * Track WhatsApp click
   */
  async trackWhatsAppClick(establishmentId) {
    const establishment = await Establishment.findByPk(establishmentId);
    if (establishment) {
      await establishment.increment("total_whatsapp_clicks");
    }
  }

  // ==================== PARTNER METHODS ====================

  /**
   * Get partner's establishments
   */
  async getPartnerEstablishments(partnerId, options = {}) {
    const { page = 1, limit = 20, status } = options;
    const offset = (page - 1) * limit;

    const where = { partner_id: partnerId };
    if (status) where.status = status;

    const { count, rows } = await Establishment.findAndCountAll({
      where,
      include: this.getDefaultIncludes(),
      order: [["created_at", "DESC"]],
      limit,
      offset,
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
   * Get partner's establishment by ID
   */
  async getPartnerEstablishmentById(partnerId, establishmentId) {
    const establishment = await Establishment.findOne({
      where: { id: establishmentId, partner_id: partnerId },
      include: this.getDefaultIncludes({ includeReviews: true }),
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    return establishment;
  }

  /**
   * Create establishment (partner)
   */
  async create(partnerId, data) {
    // Verify partner exists and is approved
    const partner = await Partner.findByPk(partnerId);
    if (!partner) {
      throw ApiError.notFound("Partner not found");
    }
    if (partner.status !== "approved") {
      throw ApiError.forbidden("Partner account is not approved");
    }

    // Verify category exists
    const category = await Category.findByPk(data.category_id);
    if (!category) {
      throw ApiError.badRequest("Category not found");
    }

    // Verify subcategory exists and belongs to category
    if (data.subcategory_id) {
      const subcategory = await SubCategory.findOne({
        where: { id: data.subcategory_id, category_id: data.category_id },
      });
      if (!subcategory) {
        throw ApiError.badRequest(
          "Subcategory not found or does not belong to selected category",
        );
      }
    }

    // Verify wilaya exists
    const wilaya = await Wilaya.findByPk(data.wilaya_id);
    if (!wilaya) {
      throw ApiError.badRequest("Wilaya not found");
    }

    // Verify commune exists and belongs to wilaya
    if (data.commune_id) {
      const commune = await Commune.findOne({
        where: { id: data.commune_id, wilaya_id: data.wilaya_id },
      });
      if (!commune) {
        throw ApiError.badRequest(
          "Commune not found or does not belong to selected wilaya",
        );
      }
    }

    // Generate unique slug
    const slug = await generateUniqueSlug(Establishment, generateSlug(data.name));

    // Create establishment
    const establishment = await Establishment.create({
      ...data,
      partner_id: partnerId,
      slug,
      status: "pending", // Requires admin approval
      is_verified: false,
      is_featured: false,
    });

    return this.getPartnerEstablishmentById(partnerId, establishment.id);
  }

  /**
   * Update establishment (partner)
   */
  async update(partnerId, establishmentId, data) {
    const establishment = await Establishment.findOne({
      where: { id: establishmentId, partner_id: partnerId },
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // If changing category, verify it exists
    if (data.category_id && data.category_id !== establishment.category_id) {
      const category = await Category.findByPk(data.category_id);
      if (!category) {
        throw ApiError.badRequest("Category not found");
      }
    }

    // If changing subcategory, verify it belongs to category
    if (data.subcategory_id) {
      const categoryId = data.category_id || establishment.category_id;
      const subcategory = await SubCategory.findOne({
        where: { id: data.subcategory_id, category_id: categoryId },
      });
      if (!subcategory) {
        throw ApiError.badRequest(
          "Subcategory not found or does not belong to selected category",
        );
      }
    }

    // If changing wilaya, verify it exists
    if (data.wilaya_id && data.wilaya_id !== establishment.wilaya_id) {
      const wilaya = await Wilaya.findByPk(data.wilaya_id);
      if (!wilaya) {
        throw ApiError.badRequest("Wilaya not found");
      }
    }

    // If changing commune, verify it belongs to wilaya
    if (data.commune_id) {
      const wilayaId = data.wilaya_id || establishment.wilaya_id;
      const commune = await Commune.findOne({
        where: { id: data.commune_id, wilaya_id: wilayaId },
      });
      if (!commune) {
        throw ApiError.badRequest(
          "Commune not found or does not belong to selected wilaya",
        );
      }
    }

    // If name changed, update slug
    if (data.name && data.name !== establishment.name) {
      data.slug = await generateUniqueSlug(
        Establishment,
        generateSlug(data.name),
        establishment.id,
      );
    }

    // Fields that partner can update
    const allowedFields = [
      "name",
      "name_ar",
      "description",
      "description_ar",
      "category_id",
      "subcategory_id",
      "wilaya_id",
      "commune_id",
      "address",
      "address_ar",
      "latitude",
      "longitude",
      "phone",
      "phone_secondary",
      "whatsapp",
      "email",
      "website",
      "facebook",
      "instagram",
      "tiktok",
      "logo",
      "cover_image",
      "images",
      "opening_hours",
      "price_range",
      "services",
      "amenities",
      "tags",
      "meta_title",
      "meta_description",
      "slug",
    ];

    const updateData = {};
    allowedFields.forEach((field) => {
      if (data[field] !== undefined) {
        updateData[field] = data[field];
      }
    });

    await establishment.update(updateData);

    return this.getPartnerEstablishmentById(partnerId, establishmentId);
  }

  /**
   * Delete establishment (partner)
   */
  async delete(partnerId, establishmentId) {
    const establishment = await Establishment.findOne({
      where: { id: establishmentId, partner_id: partnerId },
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    await establishment.destroy();

    return { message: "Establishment deleted successfully" };
  }

  /**
   * Update establishment status (partner can only deactivate)
   */
  async updateStatus(partnerId, establishmentId, status) {
    const establishment = await Establishment.findOne({
      where: { id: establishmentId, partner_id: partnerId },
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // Partner can only set to inactive or request reactivation
    if (!["inactive", "pending"].includes(status)) {
      throw ApiError.forbidden(
        "Invalid status. Partners can only deactivate or request reactivation.",
      );
    }

    await establishment.update({ status });

    return establishment;
  }

  /**
   * Get partner statistics
   */
  async getPartnerStats(partnerId) {
    const establishments = await Establishment.findAll({
      where: { partner_id: partnerId },
      attributes: [
        "id",
        "status",
        "total_views",
        "total_favorites",
        "total_calls",
        "total_whatsapp_clicks",
        "total_reviews",
        "average_rating",
      ],
    });

    const stats = {
      total_establishments: establishments.length,
      by_status: {
        active: 0,
        pending: 0,
        inactive: 0,
        rejected: 0,
      },
      totals: {
        views: 0,
        favorites: 0,
        calls: 0,
        whatsapp_clicks: 0,
        reviews: 0,
      },
      average_rating: 0,
    };

    let totalRating = 0;
    let ratedCount = 0;

    establishments.forEach((est) => {
      // Count by status
      if (stats.by_status[est.status] !== undefined) {
        stats.by_status[est.status]++;
      }

      // Sum totals
      stats.totals.views += est.total_views || 0;
      stats.totals.favorites += est.total_favorites || 0;
      stats.totals.calls += est.total_calls || 0;
      stats.totals.whatsapp_clicks += est.total_whatsapp_clicks || 0;
      stats.totals.reviews += est.total_reviews || 0;

      // Average rating
      if (est.average_rating && est.total_reviews > 0) {
        totalRating += parseFloat(est.average_rating);
        ratedCount++;
      }
    });

    if (ratedCount > 0) {
      stats.average_rating = (totalRating / ratedCount).toFixed(2);
    }

    return stats;
  }
}

module.exports = new EstablishmentService();
