const express = require("express");
const router = express.Router();

const authRoutes = require("./auth.routes");
const wilayaRoutes = require("./wilaya.routes");
const categoryRoutes = require("./category.routes");
const subcategoryRoutes = require("./subcategory.routes");
const adminRoutes = require("./admin.routes");
const establishmentRoutes = require("./establishment.routes");
const partnerRoutes = require("./partner.routes");
const favoriteRoutes = require("./favorite.routes");
const reviewRoutes = require("./review.routes");
const uploadRoutes = require("./upload.routes");
const notificationRoutes = require("./notification.routes");
const suggestionRoutes = require("./suggestion.routes");

// ── Track app visit (public, no auth) ────────────────────────────────────────
router.post("/app/visit", async (req, res) => {
  try {
    const { AppSession } = require("../models");
    const { platform, user_id } = req.body;
    await AppSession.create({
      user_id: user_id || null,
      platform: ["android", "ios", "web"].includes(platform) ? platform : null,
    });
  } catch (_) {
    // Silently ignore — le tracking ne doit jamais bloquer l'appli
  }
  res.status(204).send();
});

// ── Deep link redirects (pour les emails — win:// non supporté partout) ──────
// Les emails contiennent https://.../r/reset?token=... qui redirige vers win://
router.get("/r/reset", (req, res) => {
  const { token } = req.query;
  if (!token) return res.status(400).send("Token manquant");
  res.redirect(`win://reset-password?token=${token}`);
});

router.get("/r/verify", (req, res) => {
  const { token } = req.query;
  if (!token) return res.status(400).send("Token manquant");
  res.redirect(`win://verify-email?token=${token}`);
});

router.get("/r/partner-dashboard", (_req, res) => {
  res.redirect("win://partner");
});

router.get("/r/admin-partners", (_req, res) => {
  res.redirect("win://admin/partners/pending");
});

router.get("/r/payment/success", (req, res) => {
  const { establishment_id } = req.query;
  if (establishment_id) {
    res.redirect(`win://partner/establishments/${establishment_id}?featured_success=1`);
  } else {
    res.redirect("win://partner/subscription?success=1");
  }
});

router.get("/r/payment/failed", (req, res) => {
  const { establishment_id } = req.query;
  if (establishment_id) {
    res.redirect(`win://partner/establishments/${establishment_id}?featured_failed=1`);
  } else {
    res.redirect("win://partner/subscription?failed=1");
  }
});

// Health check
router.get("/health", (req, res) => {
  res.json({
    success: true,
    message: "API is running",
    timestamp: new Date().toISOString(),
    version: process.env.API_VERSION || "v1",
  });
});

// Mount routes
router.use("/auth", authRoutes);
router.use("/wilayas", wilayaRoutes);
router.use("/categories", categoryRoutes);
router.use("/subcategories", subcategoryRoutes);
router.use("/admin", adminRoutes);
router.use("/establishments", establishmentRoutes);
router.use("/partner", partnerRoutes);
router.use("/favorites", favoriteRoutes);
router.use("/reviews", reviewRoutes);
router.use("/upload", uploadRoutes);
router.use("/notifications", notificationRoutes);
router.use("/suggestions", suggestionRoutes);

// ── DEV ONLY: Simulate Chargily webhook (activate subscription manually) ──────
// This endpoint is disabled in production and is for local testing only.
if (process.env.NODE_ENV !== "production") {
  router.post("/dev/activate-subscription", async (req, res, next) => {
    try {
      const { partner_id, plan } = req.body;
      if (!partner_id || !plan) {
        return res
          .status(400)
          .json({ success: false, message: "partner_id et plan requis" });
      }
      const subscriptionService = require("../services/subscription.service");
      await subscriptionService._activateSubscription(
        partner_id,
        plan,
        `dev-test-${Date.now()}`
      );
      res.json({
        success: true,
        message: `Abonnement "${plan}" activé pour le partenaire ${partner_id}`,
      });
    } catch (err) {
      next(err);
    }
  });
}

module.exports = router;
