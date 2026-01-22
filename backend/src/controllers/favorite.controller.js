const favoriteService = require("../services/favorite.service");
const { ApiResponse } = require("../utils");

class FavoriteController {
  /**
   * Get my favorites
   * GET /api/v1/favorites
   */
  async getMyFavorites(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        category_id: req.query.category_id,
        wilaya_id: req.query.wilaya_id,
      };

      const result = await favoriteService.getUserFavorites(
        req.userId,
        options,
      );
      ApiResponse.success(result, "Favorites retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Add to favorites
   * POST /api/v1/favorites/:establishmentId
   */
  async addFavorite(req, res, next) {
    try {
      const { establishmentId } = req.params;
      const result = await favoriteService.addFavorite(
        req.userId,
        establishmentId,
      );
      ApiResponse.created(result, "Added to favorites").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Remove from favorites
   * DELETE /api/v1/favorites/:establishmentId
   */
  async removeFavorite(req, res, next) {
    try {
      const { establishmentId } = req.params;
      const result = await favoriteService.removeFavorite(
        req.userId,
        establishmentId,
      );
      ApiResponse.success(null, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Toggle favorite
   * POST /api/v1/favorites/:establishmentId/toggle
   */
  async toggleFavorite(req, res, next) {
    try {
      const { establishmentId } = req.params;
      const result = await favoriteService.toggleFavorite(
        req.userId,
        establishmentId,
      );
      ApiResponse.success(result, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Check if favorited
   * GET /api/v1/favorites/:establishmentId/check
   */
  async checkFavorite(req, res, next) {
    try {
      const { establishmentId } = req.params;
      const result = await favoriteService.isFavorited(
        req.userId,
        establishmentId,
      );
      ApiResponse.success(result, "Favorite status checked").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Check multiple favorites
   * POST /api/v1/favorites/check-multiple
   */
  async checkMultipleFavorites(req, res, next) {
    try {
      const { establishment_ids } = req.body;

      if (!establishment_ids || !Array.isArray(establishment_ids)) {
        return ApiResponse.success({}, "No establishment IDs provided").send(
          res,
        );
      }

      const result = await favoriteService.checkMultipleFavorites(
        req.userId,
        establishment_ids,
      );
      ApiResponse.success(result, "Favorites status checked").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get favorites count
   * GET /api/v1/favorites/count
   */
  async getFavoritesCount(req, res, next) {
    try {
      const result = await favoriteService.getFavoritesCount(req.userId);
      ApiResponse.success(result, "Favorites count retrieved").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Clear all favorites
   * DELETE /api/v1/favorites
   */
  async clearAllFavorites(req, res, next) {
    try {
      const result = await favoriteService.clearAllFavorites(req.userId);
      ApiResponse.success(result, result.message).send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new FavoriteController();
