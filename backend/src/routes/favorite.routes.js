const express = require("express");
const router = express.Router();
const favoriteController = require("../controllers/favorite.controller");
const { authenticate } = require("../middlewares/auth");

// All favorite routes require authentication
router.use(authenticate);

/**
 * @route   GET /api/v1/favorites
 * @desc    Get my favorites
 * @access  Private
 * @query   page, limit, category_id, wilaya_id
 */
router.get("/", favoriteController.getMyFavorites);

/**
 * @route   GET /api/v1/favorites/count
 * @desc    Get favorites count
 * @access  Private
 */
router.get("/count", favoriteController.getFavoritesCount);

/**
 * @route   POST /api/v1/favorites/check-multiple
 * @desc    Check favorite status for multiple establishments
 * @access  Private
 * @body    { establishment_ids: ["uuid1", "uuid2"] }
 */
router.post("/check-multiple", favoriteController.checkMultipleFavorites);

/**
 * @route   GET /api/v1/favorites/:establishmentId/check
 * @desc    Check if establishment is favorited
 * @access  Private
 */
router.get("/:establishmentId/check", favoriteController.checkFavorite);

/**
 * @route   POST /api/v1/favorites/:establishmentId/toggle
 * @desc    Toggle favorite (add/remove)
 * @access  Private
 */
router.post("/:establishmentId/toggle", favoriteController.toggleFavorite);

/**
 * @route   POST /api/v1/favorites/:establishmentId
 * @desc    Add to favorites
 * @access  Private
 */
router.post("/:establishmentId", favoriteController.addFavorite);

/**
 * @route   DELETE /api/v1/favorites/:establishmentId
 * @desc    Remove from favorites
 * @access  Private
 */
router.delete("/:establishmentId", favoriteController.removeFavorite);

/**
 * @route   DELETE /api/v1/favorites
 * @desc    Clear all favorites
 * @access  Private
 */
router.delete("/", favoriteController.clearAllFavorites);

module.exports = router;
