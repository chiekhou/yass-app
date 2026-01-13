const express = require("express");
const router = express.Router();

const authRoutes = require("./auth.routes");

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

// Future routes will be added here:
// router.use('/categories', categoryRoutes);
// router.use('/establishments', establishmentRoutes);
// router.use('/reviews', reviewRoutes);
// router.use('/favorites', favoritesRoutes);
// router.use('/promotions', promotionRoutes);
// router.use('/wilayas', wilayaRoutes);
// router.use('/admin', adminRoutes);
// router.use('/partner', partnerRoutes);

module.exports = router;
