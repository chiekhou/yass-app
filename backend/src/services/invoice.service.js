const { Invoice, Partner, Establishment } = require("../models");
const config = require("../config/app");
const ApiError = require("../utils/ApiError");
const notificationService = require("./notification.service");

class InvoiceService {
  // ─── Génération du numéro de facture ─────────────────────────────────────

  async generateInvoiceNumber() {
    const year = new Date().getFullYear();
    const count = await Invoice.count({
      where: require("sequelize").literal(
        `EXTRACT(YEAR FROM created_at) = ${year}`
      ),
    });
    const padded = String(count + 1).padStart(4, "0");
    return `YASS-${year}-${padded}`;
  }

  // ─── Créer une facture ───────────────────────────────────────────────────

  async createInvoice({
    partner,
    plan,
    method,
    type = "subscription",
    establishmentId = null,
    featuredDurationDays = null,
    chargilyCheckoutId = null,
    chargilyCheckoutUrl = null,
    transferReference = null,
    periodStart = null,
    periodEnd = null,
    status = "pending_validation",
    paidAt = null,
  }) {
    // Chercher le plan dans subscription ou featured selon le type
    const planConfig =
      config.chargily.plans[plan] || config.chargily.featuredPlans[plan];
    if (!planConfig) {
      throw ApiError.badRequest(`Plan invalide : ${plan}`);
    }

    const now = new Date();
    const start = periodStart || now;
    const end =
      periodEnd ||
      new Date(now.getTime() + planConfig.days * 24 * 60 * 60 * 1000);

    const invoiceNumber = await this.generateInvoiceNumber();

    const invoice = await Invoice.create({
      invoice_number: invoiceNumber,
      partner_id: partner.id,
      type,
      plan,
      establishment_id: establishmentId,
      featured_duration_days: featuredDurationDays,
      amount: planConfig.amount,
      currency: "DZD",
      payment_method: method,
      status,
      chargily_checkout_id: chargilyCheckoutId,
      chargily_checkout_url: chargilyCheckoutUrl,
      transfer_reference: transferReference,
      period_start: start,
      period_end: end,
      paid_at: paidAt,
    });

    return invoice;
  }

  // ─── Activer la mise à la une après paiement ────────────────────────────

  async activateFeatured(invoice) {
    if (!invoice.establishment_id || !invoice.featured_duration_days) return;

    const now = new Date();
    const featuredUntil = new Date(
      now.getTime() + invoice.featured_duration_days * 24 * 60 * 60 * 1000
    );

    await Establishment.update(
      { is_featured: true, featured_until: featuredUntil },
      { where: { id: invoice.establishment_id } }
    );
  }

  // ─── Liste des factures d'un partenaire ──────────────────────────────────

  async getPartnerInvoices(partnerId) {
    const invoices = await Invoice.findAll({
      where: { partner_id: partnerId },
      order: [["created_at", "DESC"]],
    });
    return invoices;
  }

  // ─── Détail d'une facture ────────────────────────────────────────────────

  async getInvoiceById(invoiceId, partnerId) {
    const invoice = await Invoice.findOne({
      where: { id: invoiceId, partner_id: partnerId },
    });

    if (!invoice) {
      throw ApiError.notFound("Facture introuvable");
    }

    return invoice;
  }

  // ─── Valider un paiement manuel (admin) ──────────────────────────────────

  async validateManualPayment(invoiceId, adminId) {
    const invoice = await Invoice.findByPk(invoiceId);
    if (!invoice) {
      throw ApiError.notFound("Facture introuvable");
    }

    if (!["manual", "cash"].includes(invoice.payment_method)) {
      throw ApiError.badRequest("Cette facture n'est pas un paiement manuel ou espèces");
    }

    if (invoice.status === "paid") {
      throw ApiError.badRequest("Cette facture est déjà validée");
    }

    const now = new Date();

    await invoice.update({
      status: "paid",
      paid_at: now,
      validated_by: adminId,
      validated_at: now,
    });

    if (invoice.type === "featured") {
      // Activer la mise à la une de l'établissement
      await this.activateFeatured(invoice);
    } else {
      // Activer l'abonnement du partenaire
      const planConfig = config.chargily.plans[invoice.plan];
      if (planConfig) {
        const expiresAt = new Date(
          now.getTime() + planConfig.days * 24 * 60 * 60 * 1000
        );
        const subscriptionPlan = invoice.plan === "yearly" ? "gold" : "premium";

        await Partner.update(
          {
            subscription_plan: subscriptionPlan,
            subscription_expires_at: expiresAt,
          },
          { where: { id: invoice.partner_id } }
        );

        if (!invoice.period_start || !invoice.period_end) {
          await invoice.update({
            period_start: now,
            period_end: expiresAt,
          });
        }

        // Gold : mise à la une automatique sur tous les établissements actifs
        if (subscriptionPlan === "gold") {
          await Establishment.update(
            { is_featured: true, featured_until: expiresAt },
            { where: { partner_id: invoice.partner_id, status: "active" } }
          );
        }
      }
    }

    const reloaded = await invoice.reload();

    // Notify partner (fire-and-forget)
    const partner = await Partner.findByPk(invoice.partner_id, { attributes: ["user_id"] });
    if (partner) {
      notificationService.notifyPaymentValidated(reloaded, partner.user_id).catch(() => {});
    }

    return reloaded;
  }

  // ─── Factures en attente de validation (admin) ───────────────────────────

  async getPendingManualPayments({ page = 1, limit = 20 } = {}) {
    const offset = (page - 1) * limit;
    const { Op } = require("sequelize");
    const { count, rows } = await Invoice.findAndCountAll({
      where: { payment_method: { [Op.in]: ["manual", "cash"] }, status: "pending_validation" },
      include: [
        {
          model: Partner,
          as: "partner",
          attributes: ["id", "company_name", "user_id"],
        },
      ],
      order: [["created_at", "ASC"]],
      limit,
      offset,
    });

    return {
      invoices: rows,
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }
}

module.exports = new InvoiceService();
