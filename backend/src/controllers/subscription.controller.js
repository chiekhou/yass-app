const subscriptionService = require("../services/subscription.service");
const ApiError = require("../utils/ApiError");

class SubscriptionController {
  /**
   * GET /partner/subscription/status
   */
  async getStatus(req, res, next) {
    try {
      const status = await subscriptionService.getStatus(req.partner);
      res.json({ success: true, data: status });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /partner/subscription/checkout
   * Body: { plan: "monthly" | "yearly" }
   * Crée une session Chargily et retourne l'URL de paiement
   */
  async createCheckout(req, res, next) {
    try {
      const { plan } = req.body;

      if (!plan || !["monthly", "yearly"].includes(plan)) {
        throw ApiError.badRequest('Le plan doit être "monthly" ou "yearly"');
      }

      const { checkoutUrl } = await subscriptionService.createChargilyCheckout(
        req.partner,
        plan
      );

      res.json({ success: true, data: { checkout_url: checkoutUrl } });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /partner/subscription/manual
   * Body: { plan: "monthly" | "yearly", transfer_reference?: string }
   * Crée une demande de paiement manuel (en attente de validation admin)
   */
  async requestManualPayment(req, res, next) {
    try {
      const { plan, transfer_reference } = req.body;

      if (!plan || !["monthly", "yearly"].includes(plan)) {
        throw ApiError.badRequest('Le plan doit être "monthly" ou "yearly"');
      }

      const result = await subscriptionService.createManualPaymentRequest(
        req.partner,
        plan,
        transfer_reference || null
      );

      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /partner/subscription/cancel
   * Annule l'abonnement actif (remet le partenaire en free)
   */
  async cancelSubscription(req, res, next) {
    try {
      const result = await subscriptionService.cancelSubscription(req.partner);
      res.json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /chargily/webhook
   * Webhook Chargily (raw body, pas d'auth)
   */
  async webhook(req, res, _next) {
    try {
      const signature = req.headers["signature"];
      if (!signature) {
        return res.status(400).json({ error: "Signature manquante" });
      }

      const result = await subscriptionService.handleWebhookEvent(
        req.body,
        signature
      );

      res.json(result);
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}

module.exports = new SubscriptionController();
