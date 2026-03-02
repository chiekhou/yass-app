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
