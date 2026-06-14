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

// ── Deep link redirects (pour les emails) ────────────────────────────────────
// Les navigateurs et clients email Android/iOS bloquent les HTTP 302 → win://
// On sert une page HTML avec window.location pour contourner cette restriction.

function deepLinkPage(deepLink, title, message) {
  const safe = deepLink.replace(/'/g, '%27');
  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title} — Win</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,sans-serif;background:#f4f4f4;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px}
    .card{background:#fff;border-radius:14px;padding:36px 28px;max-width:420px;width:100%;text-align:center;box-shadow:0 4px 16px rgba(0,0,0,.1)}
    h2{color:#006233;font-size:20px;margin-bottom:12px}
    p{color:#555;font-size:14px;line-height:1.5;margin-bottom:24px}
    .btn{display:inline-block;padding:14px 32px;background:#006233;color:#fff;text-decoration:none;border-radius:8px;font-size:15px;font-weight:700}
    .note{margin-top:20px;font-size:12px;color:#999}
  </style>
  <script>window.onload=function(){window.location.href='${safe}';};</script>
</head>
<body>
  <div class="card">
    <h2>${title}</h2>
    <p>${message}</p>
    <a href="${safe}" class="btn">Ouvrir Win</a>
    <p class="note">Si l'application ne s'ouvre pas, assurez-vous qu'elle est installée sur votre appareil.</p>
  </div>
</body>
</html>`;
}

router.get("/r/reset", (req, res) => {
  const { token } = req.query;
  if (!token) return res.status(400).send("Token manquant");
  const deepLink = `win://reset-password?token=${encodeURIComponent(token)}`;
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.send(deepLinkPage(
    deepLink,
    "🔐 Réinitialisation du mot de passe",
    "L'application Win devrait s'ouvrir automatiquement pour vous permettre de définir un nouveau mot de passe."
  ));
});

router.get("/r/verify", (req, res) => {
  const { token } = req.query;
  if (!token) return res.status(400).send("Token manquant");
  const deepLink = `win://verify-email?token=${encodeURIComponent(token)}`;
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.send(deepLinkPage(
    deepLink,
    "✅ Vérification de votre email",
    "L'application Win devrait s'ouvrir automatiquement pour confirmer votre adresse email."
  ));
});

router.get("/r/welcome", (_req, res) => {
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.send(deepLinkPage("win://main", "🎉 Bienvenue sur Win !", "Votre compte est activé. L'application s'ouvre automatiquement."));
});

router.get("/r/partner-dashboard", (_req, res) => {
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.send(deepLinkPage("win://partner", "🏢 Espace partenaire", "L'application Win s'ouvre automatiquement vers votre espace partenaire."));
});

router.get("/r/admin-partners", (_req, res) => {
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.send(deepLinkPage("win://admin/partners/pending", "🔔 Demandes partenaires", "L'application s'ouvre automatiquement vers la liste des demandes."));
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
