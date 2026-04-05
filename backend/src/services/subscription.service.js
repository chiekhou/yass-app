const crypto = require("crypto");
const axios = require("axios");
const config = require("../config/app");
const { Partner, Invoice } = require("../models");
const ApiError = require("../utils/ApiError");

const CHARGILY_BASE_URL =
  config.chargily.mode === "live"
    ? "https://pay.chargily.net/api/v2"
    : "https://pay.chargily.net/test/api/v2";

const PLAN_LABELS = {
  free: "Gratuit",
  premium: "Mensuel",
  gold: "Annuel",
};

class SubscriptionService {
  // ─── Statut abonnement ───────────────────────────────────────────────────

  async getStatus(partner) {
    const now = new Date();
    const plan = partner.subscription_plan || "free";

    const isActive =
      plan !== "free" &&
      partner.subscription_expires_at != null &&
      new Date(partner.subscription_expires_at) > now;

    const daysRemaining = isActive
      ? Math.ceil(
          (new Date(partner.subscription_expires_at) - now) /
            (1000 * 60 * 60 * 24),
        )
      : 0;

    const pendingInvoice = await Invoice.findOne({
      where: { partner_id: partner.id, status: "pending_validation" },
    });

    return {
      plan,
      plan_label: PLAN_LABELS[plan] || plan,
      is_in_trial: false,
      is_active: isActive,
      trial_expired: false,
      is_visible: true, // Basic est toujours visible
      days_remaining: daysRemaining,
      trial_ends_at: null,
      subscription_ends_at: partner.subscription_expires_at || null,
      chargily_checkout_id: partner.chargily_checkout_id || null,
      has_pending_payment: !!pendingInvoice,
    };
  }

  // ─── Chargily : créer une session de paiement ────────────────────────────

  async createChargilyCheckout(partner, plan) {
    if (!config.chargily.apiKey) {
      throw ApiError.internal("Chargily non configuré");
    }

    const planConfig = config.chargily.plans[plan];
    if (!planConfig) {
      throw ApiError.badRequest(`Plan invalide : ${plan}`);
    }

    const successUrl = `${config.urls.app}/api/${config.apiVersion}/r/payment/success`;
    const failureUrl = `${config.urls.app}/api/${config.apiVersion}/r/payment/failed`;
    const webhookUrl = `${config.urls.app}/api/${config.apiVersion}/chargily/webhook`;

    const payload = {
      amount: planConfig.amount,
      currency: "dzd",
      success_url: successUrl,
      failure_url: failureUrl,
      webhook_endpoint: webhookUrl,
      locale: "fr",
      metadata: {
        partner_id: partner.id,
        plan,
      },
    };

    try {
      const response = await axios.post(
        `${CHARGILY_BASE_URL}/checkouts`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${config.chargily.apiKey}`,
            "Content-Type": "application/json",
          },
        },
      );

      return {
        checkoutId: response.data.id,
        checkoutUrl: response.data.checkout_url,
      };
    } catch (err) {
      // console.error("Chargily error details:", err.response?.data); // peut exposer des données de paiement
      const msg = err.response?.data?.message || err.message;
      throw ApiError.internal(`Erreur Chargily : ${msg}`);
    }
  }

  // ─── Chargily : session de paiement pour mise à la une ──────────────────

  async createFeaturedChargilyCheckout(partner, establishmentId, plan) {
    if (!config.chargily.apiKey) {
      throw ApiError.internal("Chargily non configuré");
    }

    const planConfig = config.chargily.featuredPlans[plan];
    if (!planConfig) {
      throw ApiError.badRequest(`Plan featured invalide : ${plan}`);
    }

    const successUrl = `${config.urls.app}/api/${config.apiVersion}/r/payment/success?establishment_id=${establishmentId}`;
    const failureUrl = `${config.urls.app}/api/${config.apiVersion}/r/payment/failed?establishment_id=${establishmentId}`;
    const webhookUrl = `${config.urls.app}/api/${config.apiVersion}/chargily/webhook`;

    const payload = {
      amount: planConfig.amount,
      currency: "dzd",
      success_url: successUrl,
      failure_url: failureUrl,
      webhook_endpoint: webhookUrl,
      locale: "fr",
      metadata: {
        partner_id: partner.id,
        plan,
        invoice_type: "featured",
        establishment_id: establishmentId,
        featured_duration_days: planConfig.days,
      },
    };

    try {
      const response = await axios.post(
        `${CHARGILY_BASE_URL}/checkouts`,
        payload,
        {
          headers: {
            Authorization: `Bearer ${config.chargily.apiKey}`,
            "Content-Type": "application/json",
          },
        },
      );

      return {
        checkoutId: response.data.id,
        checkoutUrl: response.data.checkout_url,
      };
    } catch (err) {
      const msg = err.response?.data?.message || err.message;
      throw ApiError.internal(`Erreur Chargily : ${msg}`);
    }
  }

  // ─── Paiement manuel / espèces pour mise à la une ───────────────────────

  async createFeaturedManualRequest(
    partner,
    establishmentId,
    plan,
    transferReference,
    paymentMethod = "manual",
  ) {
    const planConfig = config.chargily.featuredPlans[plan];
    if (!planConfig) {
      throw ApiError.badRequest(`Plan featured invalide : ${plan}`);
    }

    // Empêche un doublon si une facture featured est déjà en attente
    const existing = await Invoice.findOne({
      where: {
        partner_id: partner.id,
        establishment_id: establishmentId,
        type: "featured",
        status: "pending_validation",
      },
    });
    if (existing) {
      throw ApiError.conflict(
        "Un paiement pour cet établissement est déjà en attente de validation.",
      );
    }

    const invoiceService = require("./invoice.service");

    const invoice = await invoiceService.createInvoice({
      partner,
      plan,
      method: paymentMethod,
      type: "featured",
      establishmentId,
      featuredDurationDays: planConfig.days,
      transferReference: transferReference || null,
    });

    // Notifie tous les admins (fire-and-forget)
    const notificationService = require("./notification.service");
    notificationService
      .notifyAdminNewPayment(invoice, partner.company_name)
      .catch(() => {});

    return {
      invoice,
      bank_details: config.chargily.bankDetails,
    };
  }

  // ─── Paiement manuel ─────────────────────────────────────────────────────

  async createManualPaymentRequest(partner, plan, transferReference) {
    const planConfig = config.chargily.plans[plan];
    if (!planConfig) {
      throw ApiError.badRequest(`Plan invalide : ${plan}`);
    }

    // Importation différée pour éviter la référence circulaire
    const invoiceService = require("./invoice.service");

    const invoice = await invoiceService.createInvoice({
      partner,
      plan,
      method: "manual",
      transferReference: transferReference || null,
    });

    // Notifie tous les admins (fire-and-forget)
    const notificationService = require("./notification.service");
    notificationService
      .notifyAdminNewPayment(invoice, partner.company_name)
      .catch(() => {});

    return {
      invoice,
      bank_details: config.chargily.bankDetails,
    };
  }

  // ─── Webhook Chargily ────────────────────────────────────────────────────

  async handleWebhookEvent(payload, signature) {
    if (!signature) {
      throw ApiError.badRequest("Signature webhook manquante");
    }

    const calculated = crypto
      .createHmac("sha256", config.chargily.apiKey)
      .update(payload)
      .digest("hex");

    let isValid = false;
    try {
      isValid = crypto.timingSafeEqual(
        Buffer.from(calculated),
        Buffer.from(signature),
      );
    } catch {
      isValid = false;
    }

    if (!isValid) {
      throw ApiError.badRequest("Signature webhook invalide");
    }

    const event = JSON.parse(payload.toString());

    if (event.type === "checkout.paid") {
      const checkout = event.data;
      const {
        partner_id,
        plan,
        invoice_type,
        establishment_id,
        featured_duration_days,
      } = checkout.metadata || {};

      if (
        invoice_type === "featured" &&
        partner_id &&
        plan &&
        establishment_id
      ) {
        await this._activateFeaturedPayment(
          partner_id,
          plan,
          establishment_id,
          Number(featured_duration_days),
          checkout.id,
        );
      } else if (partner_id && plan) {
        await this._activateSubscription(partner_id, plan, checkout.id);
      }
    }

    return { received: true, type: event.type };
  }

  // ─── Annulation abonnement ───────────────────────────────────────────────

  async cancelSubscription(partner) {
    const now = new Date();
    const isActive =
      partner.subscription_plan !== "free" &&
      partner.subscription_expires_at != null &&
      new Date(partner.subscription_expires_at) > now;

    if (!isActive) {
      throw ApiError.badRequest("Aucun abonnement actif à annuler");
    }

    const wasGold = partner.subscription_plan === "gold";

    await partner.update({
      subscription_plan: "free",
      subscription_expires_at: null,
      chargily_checkout_id: null,
    });

    // Si le plan était Gold, retirer la mise à la une automatique des établissements
    if (wasGold) {
      const { Establishment } = require("../models");
      await Establishment.update(
        { is_featured: false, featured_until: null },
        { where: { partner_id: partner.id, is_featured: true } }
      );
    }

    return { message: "Abonnement annulé avec succès" };
  }

  // ─── Activation mise à la une via Chargily ───────────────────────────────

  async _activateFeaturedPayment(
    partnerId,
    plan,
    establishmentId,
    durationDays,
    chargilyCheckoutId,
  ) {
    const partner = await Partner.findByPk(partnerId);
    if (!partner) return;

    const now = new Date();
    const invoiceService = require("./invoice.service");

    const invoice = await invoiceService.createInvoice({
      partner,
      plan,
      method: "chargily",
      type: "featured",
      establishmentId,
      featuredDurationDays: durationDays,
      chargilyCheckoutId,
      status: "paid",
      paidAt: now,
    });

    await invoiceService.activateFeatured(invoice);

    const notificationService = require("./notification.service");
    notificationService.notifyPaymentValidated(invoice, partner.user_id).catch(() => {});
  }

  // ─── Activation abonnement ───────────────────────────────────────────────

  async _activateSubscription(partnerId, plan, chargilyCheckoutId) {
    const planConfig = config.chargily.plans[plan];
    if (!planConfig) return;

    const partner = await Partner.findByPk(partnerId);
    if (!partner) return;

    const now = new Date();
    const expiresAt = new Date(
      now.getTime() + planConfig.days * 24 * 60 * 60 * 1000,
    );
    const subscriptionPlan = plan === "yearly" ? "gold" : "premium";

    await partner.update({
      subscription_plan: subscriptionPlan,
      subscription_expires_at: expiresAt,
      chargily_checkout_id: chargilyCheckoutId,
    });

    // Gold : mise à la une automatique sur tous les établissements actifs
    if (subscriptionPlan === "gold") {
      const { Establishment } = require("../models");
      await Establishment.update(
        { is_featured: true, featured_until: expiresAt },
        { where: { partner_id: partnerId, status: "active" } },
      );
    }

    const invoiceService = require("./invoice.service");
    const invoice = await invoiceService.createInvoice({
      partner,
      plan,
      method: "chargily",
      chargilyCheckoutId,
      periodStart: now,
      periodEnd: expiresAt,
      status: "paid",
      paidAt: now,
    });

    const notificationService = require("./notification.service");
    notificationService.notifyPaymentValidated(invoice, partner.user_id).catch(() => {});
  }
}

module.exports = new SubscriptionService();
