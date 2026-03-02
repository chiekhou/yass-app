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

    const isInTrial =
      plan === "free" &&
      partner.trial_ends_at != null &&
      new Date(partner.trial_ends_at) > now;

    const isActive =
      plan !== "free" &&
      partner.subscription_expires_at != null &&
      new Date(partner.subscription_expires_at) > now;

    const trialExpired =
      plan === "free" &&
      (partner.trial_ends_at == null || new Date(partner.trial_ends_at) <= now);

    let daysRemaining = 0;
    if (isInTrial) {
      daysRemaining = Math.ceil(
        (new Date(partner.trial_ends_at) - now) / (1000 * 60 * 60 * 24)
      );
    } else if (isActive) {
      daysRemaining = Math.ceil(
        (new Date(partner.subscription_expires_at) - now) / (1000 * 60 * 60 * 24)
      );
    }

    const pendingInvoice = await Invoice.findOne({
      where: { partner_id: partner.id, status: "pending_validation" },
    });

    return {
      plan,
      plan_label: PLAN_LABELS[plan] || plan,
      is_in_trial: isInTrial,
      is_active: isActive,
      trial_expired: trialExpired,
      is_visible: isInTrial || isActive,
      days_remaining: daysRemaining,
      trial_ends_at: partner.trial_ends_at || null,
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

    const successUrl = `${config.urls.frontend}/partner/subscription?success=1`;
    const failureUrl = `${config.urls.frontend}/partner/subscription?failed=1`;
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
        }
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
        Buffer.from(signature)
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
      const { partner_id, plan } = checkout.metadata || {};
      if (partner_id && plan) {
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

    await partner.update({
      subscription_plan: "free",
      subscription_expires_at: null,
      chargily_checkout_id: null,
    });

    return { message: "Abonnement annulé avec succès" };
  }

  // ─── Activation abonnement ───────────────────────────────────────────────

  async _activateSubscription(partnerId, plan, chargilyCheckoutId) {
    const planConfig = config.chargily.plans[plan];
    if (!planConfig) return;

    const partner = await Partner.findByPk(partnerId);
    if (!partner) return;

    const now = new Date();
    const expiresAt = new Date(
      now.getTime() + planConfig.days * 24 * 60 * 60 * 1000
    );
    const subscriptionPlan = plan === "yearly" ? "gold" : "premium";

    await partner.update({
      subscription_plan: subscriptionPlan,
      subscription_expires_at: expiresAt,
      chargily_checkout_id: chargilyCheckoutId,
    });

    const invoiceService = require("./invoice.service");
    await invoiceService.createInvoice({
      partner,
      plan,
      method: "chargily",
      chargilyCheckoutId,
      periodStart: now,
      periodEnd: expiresAt,
      status: "paid",
      paidAt: now,
    });
  }
}

module.exports = new SubscriptionService();
