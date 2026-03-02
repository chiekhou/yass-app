const { Invoice, Partner } = require("../models");
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
    chargilyCheckoutId = null,
    chargilyCheckoutUrl = null,
    transferReference = null,
    periodStart = null,
    periodEnd = null,
    status = "pending_validation",
    paidAt = null,
  }) {
    const planConfig = config.chargily.plans[plan];
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
      plan,
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

    if (invoice.payment_method !== "manual") {
      throw ApiError.badRequest("Cette facture n'est pas un paiement manuel");
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

      // Mettre à jour les dates de la facture si elles ne sont pas définies
      if (!invoice.period_start || !invoice.period_end) {
        await invoice.update({
          period_start: now,
          period_end: expiresAt,
        });
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
    const { count, rows } = await Invoice.findAndCountAll({
      where: { payment_method: "manual", status: "pending_validation" },
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
