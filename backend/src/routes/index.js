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

// Future routes will be added here:
// router.use('/promotions', promotionRoutes);

module.exports = router;
