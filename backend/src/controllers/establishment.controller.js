const establishmentService = require("../services/establishment.service");
const { ApiResponse } = require("../utils");

class EstablishmentController {
  // ==================== PUBLIC ROUTES ====================

  /**
   * Search establishments
   * GET /api/v1/establishments
   */
  async search(req, res, next) {
    try {
      const filters = {
        q: req.query.q,
        category_id: req.query.category_id,
        subcategory_id: req.query.subcategory_id,
        wilaya_id: req.query.wilaya_id,
        commune_id: req.query.commune_id,
        price_range: req.query.price_range,
        is_verified: req.query.is_verified,
        is_featured: req.query.is_featured,
        min_rating: req.query.min_rating,
        latitude: req.query.latitude,
        longitude: req.query.longitude,
        radius: req.query.radius,
        services: req.query.services
          ? req.query.services.split(",")
          : undefined,
        amenities: req.query.amenities
          ? req.query.amenities.split(",")
          : undefined,
        tags: req.query.tags ? req.query.tags.split(",") : undefined,
        sort_by: req.query.sort_by,
        sort_order: req.query.sort_order,
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
      };

      const result = await establishmentService.search(filters);
      ApiResponse.success(result, "Establishments retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get establishment by ID
   * GET /api/v1/establishments/:id
   */
  async getById(req, res, next) {
    try {
      const userId = req.userId || null;
      const establishment = await establishmentService.getById(req.params.id, {
        userId,
      });
      ApiResponse.success(
        establishment,
        "Establishment retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get establishment by slug
   * GET /api/v1/establishments/slug/:slug
   */
  async getBySlug(req, res, next) {
    try {
      const userId = req.userId || null;
      const establishment = await establishmentService.getBySlug(
        req.params.slug,
        { userId },
      );
      ApiResponse.success(
        establishment,
        "Establishment retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get featured establishments
   * GET /api/v1/establishments/featured
   */
  async getFeatured(req, res, next) {
    try {
      const limit = parseInt(req.query.limit) || 10;
      const establishments = await establishmentService.getFeatured(limit);
      ApiResponse.success(
        establishments,
        "Featured establishments retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get nearby establishments
   * GET /api/v1/establishments/nearby
   */
  async getNearby(req, res, next) {
    try {
      const { latitude, longitude, radius, limit } = req.query;

      if (!latitude || !longitude) {
        return ApiResponse.success(
          [],
          "Latitude and longitude are required",
        ).send(res);
      }

      const establishments = await establishmentService.getNearby(
        latitude,
        longitude,
        radius || 10,
        parseInt(limit) || 20,
      );

      ApiResponse.success(
        establishments,
        "Nearby establishments retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get establishments by category
   * GET /api/v1/establishments/category/:categoryId
   */
  async getByCategory(req, res, next) {
    try {
      const { categoryId } = req.params;
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        wilaya_id: req.query.wilaya_id,
      };

      const result = await establishmentService.getByCategory(
        categoryId,
        options,
      );
      ApiResponse.success(result, "Establishments retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get establishments by wilaya
   * GET /api/v1/establishments/wilaya/:wilayaId
   */
  async getByWilaya(req, res, next) {
    try {
      const { wilayaId } = req.params;
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        category_id: req.query.category_id,
      };

      const result = await establishmentService.getByWilaya(wilayaId, options);
      ApiResponse.success(result, "Establishments retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Track phone click
   * POST /api/v1/establishments/:id/track/phone
   */
  async trackPhoneClick(req, res, next) {
    try {
      await establishmentService.trackPhoneClick(req.params.id);
      ApiResponse.success(null, "Phone click tracked").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Track WhatsApp click
   * POST /api/v1/establishments/:id/track/whatsapp
   */
  async trackWhatsAppClick(req, res, next) {
    try {
      await establishmentService.trackWhatsAppClick(req.params.id);
      ApiResponse.success(null, "WhatsApp click tracked").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Track contact form submission
   * POST /api/v1/establishments/:id/track/contact
   */
  async trackContact(req, res, next) {
    try {
      const { name, email, message } = req.body;
      await establishmentService.trackContact(req.params.id, {
        name: name || "Anonyme",
        senderEmail: email || "",
        message: message || "",
      });
      ApiResponse.success(null, "Message envoyé avec succès").send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== PARTNER ROUTES ====================

  /**
   * Get my establishments (partner)
   * GET /api/v1/partner/establishments
   */
  async getMyEstablishments(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        status: req.query.status,
      };

      const result = await establishmentService.getPartnerEstablishments(
        req.partnerId,
        options,
      );
      ApiResponse.success(result, "Establishments retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get my establishment by ID (partner)
   * GET /api/v1/partner/establishments/:id
   */
  async getMyEstablishmentById(req, res, next) {
    try {
      const establishment =
        await establishmentService.getPartnerEstablishmentById(
          req.partnerId,
          req.params.id,
        );
      ApiResponse.success(
        establishment,
        "Establishment retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create establishment (partner)
   * POST /api/v1/partner/establishments
   */
  async create(req, res, next) {
    try {
      const establishment = await establishmentService.create(
        req.partnerId,
        req.body,
      );
      ApiResponse.created(
        establishment,
        "Establishment created successfully. Pending admin approval.",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update establishment (partner)
   * PUT /api/v1/partner/establishments/:id
   */
  async update(req, res, next) {
    try {
      const establishment = await establishmentService.update(
        req.partnerId,
        req.params.id,
        req.body,
      );
      ApiResponse.success(
        establishment,
        "Establishment updated successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete establishment (partner)
   * DELETE /api/v1/partner/establishments/:id
   */
  async delete(req, res, next) {
    try {
      const result = await establishmentService.delete(
        req.partnerId,
        req.params.id,
      );
      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update establishment status (partner)
   * PATCH /api/v1/partner/establishments/:id/status
   */
  async updateStatus(req, res, next) {
    try {
      const { status } = req.body;
      const establishment = await establishmentService.updateStatus(
        req.partnerId,
        req.params.id,
        status,
      );
      ApiResponse.success(establishment, "Establishment status updated").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get partner statistics
   * GET /api/v1/partner/stats
   */
  async getStats(req, res, next) {
    try {
      const stats = await establishmentService.getPartnerStats(req.partnerId);
      ApiResponse.success(stats, "Statistics retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new EstablishmentController();
