const adminService = require("../services/admin.service");
const { ApiResponse } = require("../utils");

class AdminController {
  /**
   * Get dashboard statistics
   * GET /api/v1/admin/dashboard
   */
  async getDashboard(req, res, next) {
    try {
      const stats = await adminService.getDashboardStats();
      ApiResponse.success(stats, "Dashboard statistics retrieved").send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== USER MANAGEMENT ====================

  /**
   * Get all users
   * GET /api/v1/admin/users
   */
  async getUsers(req, res, next) {
    try {
      const { page, limit, role, status, search } = req.query;
      const result = await adminService.getUsers({
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
        role,
        status,
        search,
      });
      ApiResponse.success(result, "Users retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get user by ID
   * GET /api/v1/admin/users/:id
   */
  async getUserById(req, res, next) {
    try {
      const user = await adminService.getUserById(req.params.id);
      ApiResponse.success(user, "User retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update user status
   * PATCH /api/v1/admin/users/:id/status
   */
  async updateUserStatus(req, res, next) {
    try {
      const { status } = req.body;
      const user = await adminService.updateUserStatus(
        req.params.id,
        status,
        req.userId,
      );
      ApiResponse.success(user, "User status updated successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Toggle elite status
   * PATCH /api/v1/admin/users/:id/elite
   */
  async toggleEliteStatus(req, res, next) {
    try {
      const user = await adminService.toggleEliteStatus(req.params.id);
      ApiResponse.success(user, `Statut Elite ${user.is_elite ? 'activé' : 'désactivé'}`).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete user
   * DELETE /api/v1/admin/users/:id
   */
  async deleteUser(req, res, next) {
    try {
      const result = await adminService.deleteUser(req.params.id, req.userId);
      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== PARTNER MANAGEMENT ====================

  /**
   * Create partner (admin-driven)
   * POST /api/v1/admin/partners
   */
  async createPartner(req, res, next) {
    try {
      const partner = await adminService.createPartner(req.body, req.userId);
      ApiResponse.success(partner, "Partner created successfully", 201).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get all partners
   * GET /api/v1/admin/partners
   */
  async getPartners(req, res, next) {
    try {
      const { page, limit, status, search } = req.query;
      const result = await adminService.getPartners({
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
        status,
        search,
      });
      ApiResponse.success(result, "Partners retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get pending partners
   * GET /api/v1/admin/partners/pending
   */
  async getPendingPartners(req, res, next) {
    try {
      const { page, limit } = req.query;
      const result = await adminService.getPendingPartners({
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
      });
      ApiResponse.success(
        result,
        "Pending partners retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get partner by ID
   * GET /api/v1/admin/partners/:id
   */
  async getPartnerById(req, res, next) {
    try {
      const partner = await adminService.getPartnerById(req.params.id);
      ApiResponse.success(partner, "Partner retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Approve partner
   * POST /api/v1/admin/partners/:id/approve
   */
  async approvePartner(req, res, next) {
    try {
      const partner = await adminService.approvePartner(
        req.params.id,
        req.userId,
      );
      ApiResponse.success(partner, "Partner approved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Reject partner
   * POST /api/v1/admin/partners/:id/reject
   */
  async rejectPartner(req, res, next) {
    try {
      const { reason } = req.body;
      const partner = await adminService.rejectPartner(
        req.params.id,
        reason,
        req.userId,
      );
      ApiResponse.success(partner, "Partner rejected").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Suspend partner
   * POST /api/v1/admin/partners/:id/suspend
   */
  async suspendPartner(req, res, next) {
    try {
      const { reason } = req.body;
      const partner = await adminService.suspendPartner(
        req.params.id,
        reason,
        req.userId,
      );
      ApiResponse.success(partner, "Partner suspended").send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== PAYMENT MANAGEMENT ====================

  /**
   * Get pending manual payments
   * GET /api/v1/admin/payments/pending
   */
  async getPendingPayments(req, res, next) {
    try {
      const { page, limit } = req.query;
      const result = await adminService.getPendingManualPayments({
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
      });
      ApiResponse.success(result, "Paiements en attente récupérés").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Validate a manual payment
   * POST /api/v1/admin/payments/:invoiceId/validate
   */
  async validatePayment(req, res, next) {
    try {
      const invoice = await adminService.validateManualPayment(
        req.params.invoiceId,
        req.userId
      );
      ApiResponse.success(invoice, "Paiement validé, abonnement activé").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Cancel a manual payment and revoke the associated subscription
   * POST /api/v1/admin/payments/:invoiceId/cancel
   */
  async cancelPayment(req, res, next) {
    try {
      const invoice = await adminService.cancelManualPayment(
        req.params.invoiceId,
        req.userId
      );
      ApiResponse.success(invoice, "Paiement annulé, abonnement révoqué").send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== ESTABLISHMENT MANAGEMENT ====================

  /**
   * Get all establishments
   * GET /api/v1/admin/establishments
   */
  async getEstablishments(req, res, next) {
    try {
      const { page, limit, status, search, subscription_plan } = req.query;
      const result = await adminService.getEstablishments({
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
        status,
        search,
        subscription_plan,
      });
      ApiResponse.success(result, "Establishments retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create establishment (admin-driven)
   * POST /api/v1/admin/establishments
   */
  async createEstablishment(req, res, next) {
    try {
      const establishment = await adminService.createEstablishment(req.body, req.userId);
      ApiResponse.success(establishment, "Establishment created successfully", 201).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get single establishment by id
   * GET /api/v1/admin/establishments/:id
   */
  async getEstablishmentById(req, res, next) {
    try {
      const establishment = await adminService.getEstablishmentById(req.params.id);
      ApiResponse.success(establishment, "Establishment retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update establishment
   * PATCH /api/v1/admin/establishments/:id
   */
  async updateEstablishment(req, res, next) {
    try {
      const establishment = await adminService.updateEstablishment(req.params.id, req.body);
      ApiResponse.success(establishment, "Establishment updated successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get pending establishments
   * GET /api/v1/admin/establishments/pending
   */
  async getPendingEstablishments(req, res, next) {
    try {
      const { page, limit } = req.query;
      const result = await adminService.getPendingEstablishments({
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
      });
      ApiResponse.success(
        result,
        "Pending establishments retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Approve establishment
   * POST /api/v1/admin/establishments/:id/approve
   */
  async approveEstablishment(req, res, next) {
    try {
      const establishment = await adminService.approveEstablishment(
        req.params.id,
        req.userId,
      );
      ApiResponse.success(
        establishment,
        "Establishment approved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Reject establishment
   * POST /api/v1/admin/establishments/:id/reject
   */
  async rejectEstablishment(req, res, next) {
    try {
      const { reason } = req.body;
      const establishment = await adminService.rejectEstablishment(
        req.params.id,
        reason,
        req.userId,
      );
      ApiResponse.success(establishment, "Establishment rejected").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete establishment
   * DELETE /api/v1/admin/establishments/:id
   */
  async deleteEstablishment(req, res, next) {
    try {
      await adminService.deleteEstablishment(req.params.id);
      ApiResponse.success(null, "Establishment deleted successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Assign a partner to an establishment
   * PATCH /api/v1/admin/establishments/:id/assign-partner
   * body: { partner_id: string | null }
   */
  async assignPartner(req, res, next) {
    try {
      const { partner_id } = req.body;
      const establishment = await adminService.assignPartner(
        req.params.id,
        partner_id || null,
      );
      ApiResponse.success(establishment, "Partenaire associé avec succès").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Set featured status (manuel gratuit)
   * POST /api/v1/admin/establishments/:id/feature
   * body: { duration_days: number | null }  — 0 = retirer
   */
  async setFeatured(req, res, next) {
    try {
      const { duration_days } = req.body;
      const establishment = await adminService.setFeatured(
        req.params.id,
        duration_days !== undefined ? duration_days : null,
      );
      ApiResponse.success(establishment, "Mise en avant mise à jour").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Générer un lien Chargily pour mise à la une (admin → partenaire)
   * POST /api/v1/admin/establishments/:id/feature/checkout
   * body: { plan: "featured_7" | "featured_15" | "featured_30" }
   */
  async featureCheckout(req, res, next) {
    try {
      const { plan } = req.body;
      const subscriptionService = require("../services/subscription.service");
      const { Establishment, Partner } = require("../models");

      const establishment = await Establishment.findByPk(req.params.id, {
        include: [{ model: Partner, as: "partner" }],
      });
      if (!establishment) {
        return next(require("../utils/ApiError").notFound("Établissement introuvable"));
      }
      if (!establishment.partner) {
        return next(require("../utils/ApiError").badRequest("Établissement sans partenaire"));
      }

      const { checkoutUrl } = await subscriptionService.createFeaturedChargilyCheckout(
        establishment.partner,
        establishment.id,
        plan
      );

      ApiResponse.success({ checkout_url: checkoutUrl }, "Lien de paiement généré").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Créer une facture manuelle pour mise à la une
   * POST /api/v1/admin/establishments/:id/feature/manual
   * body: { plan: "featured_7" | "featured_15" | "featured_30", transfer_reference?: string }
   */
  async featureManual(req, res, next) {
    try {
      const { plan, transfer_reference, payment_method } = req.body;
      const subscriptionService = require("../services/subscription.service");
      const { Establishment, Partner } = require("../models");

      const establishment = await Establishment.findByPk(req.params.id, {
        include: [{ model: Partner, as: "partner" }],
      });
      if (!establishment) {
        return next(require("../utils/ApiError").notFound("Établissement introuvable"));
      }
      if (!establishment.partner) {
        return next(require("../utils/ApiError").badRequest("Établissement sans partenaire"));
      }

      const method = payment_method === "cash" ? "cash" : "manual";

      const result = await subscriptionService.createFeaturedManualRequest(
        establishment.partner,
        establishment.id,
        plan,
        transfer_reference || null,
        method
      );

      ApiResponse.success(result, "Facture manuelle mise à la une créée").send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== WILAYA AVAILABILITY ====================

  async getAdminWilayas(req, res, next) {
    try {
      const wilayaService = require("../services/wilaya.service");
      const wilayas = await wilayaService.getAllWilayas({ activeOnly: false });
      ApiResponse.success(wilayas, "Wilayas retrieved").send(res);
    } catch (error) {
      next(error);
    }
  }

  async toggleWilayaAvailability(req, res, next) {
    try {
      const { Wilaya } = require("../models");
      const { ApiError } = require("../utils");
      const wilaya = await Wilaya.findByPk(req.params.id);
      if (!wilaya) throw ApiError.notFound("Wilaya introuvable");
      wilaya.is_active = !wilaya.is_active;
      await wilaya.save();
      ApiResponse.success(
        { id: wilaya.id, is_active: wilaya.is_active },
        `Wilaya ${wilaya.is_active ? "activée" : "désactivée"}`
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== CATEGORY AVAILABILITY ====================

  async getAdminCategories(req, res, next) {
    try {
      const categoryService = require("../services/category.service");
      const categories = await categoryService.getAllCategories({ activeOnly: false });
      ApiResponse.success(categories, "Categories retrieved").send(res);
    } catch (error) {
      next(error);
    }
  }

  async toggleCategoryAvailability(req, res, next) {
    try {
      const { Category } = require("../models");
      const { ApiError } = require("../utils");
      const category = await Category.findByPk(req.params.id);
      if (!category) throw ApiError.notFound("Catégorie introuvable");
      category.is_active = !category.is_active;
      await category.save();
      ApiResponse.success(
        { id: category.id, is_active: category.is_active },
        `Catégorie ${category.is_active ? "activée" : "désactivée"}`
      ).send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AdminController();
