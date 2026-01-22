const {
  Favorite,
  Establishment,
  Category,
  SubCategory,
  Wilaya,
  Commune,
} = require("../models");
const ApiError = require("../utils/ApiError");
const { Op } = require("sequelize");

class FavoriteService {
  /**
   * Get user's favorites
   */
  async getUserFavorites(userId, options = {}) {
    const { page = 1, limit = 20, category_id, wilaya_id } = options;
    const offset = (page - 1) * limit;

    // Build establishment filter
    const establishmentWhere = { status: "active" };
    if (category_id) establishmentWhere.category_id = category_id;
    if (wilaya_id) establishmentWhere.wilaya_id = wilaya_id;

    const { count, rows } = await Favorite.findAndCountAll({
      where: { user_id: userId },
      include: [
        {
          model: Establishment,
          as: "establishment",
          where: establishmentWhere,
          include: [
            {
              model: Category,
              as: "category",
              attributes: ["id", "name", "name_ar", "slug", "icon", "color"],
            },
            {
              model: SubCategory,
              as: "subcategory",
              attributes: ["id", "name", "name_ar", "slug"],
            },
            {
              model: Wilaya,
              as: "wilaya",
              attributes: ["id", "code", "name", "name_ar"],
            },
            {
              model: Commune,
              as: "commune",
              attributes: ["id", "name", "name_ar"],
            },
          ],
        },
      ],
      order: [["created_at", "DESC"]],
      limit,
      offset,
    });

    return {
      favorites: rows.map((fav) => ({
        id: fav.id,
        added_at: fav.created_at,
        establishment: fav.establishment,
      })),
      pagination: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  /**
   * Add establishment to favorites
   */
  async addFavorite(userId, establishmentId) {
    // Check if establishment exists and is active
    const establishment = await Establishment.findOne({
      where: { id: establishmentId, status: "active" },
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // Check if already favorited
    const existingFavorite = await Favorite.findOne({
      where: { user_id: userId, establishment_id: establishmentId },
    });

    if (existingFavorite) {
      throw ApiError.badRequest("Establishment already in favorites");
    }

    // Create favorite
    const favorite = await Favorite.create({
      user_id: userId,
      establishment_id: establishmentId,
    });

    // Increment establishment favorites count
    await establishment.increment("total_favorites");

    return {
      id: favorite.id,
      establishment_id: establishmentId,
      added_at: favorite.created_at,
    };
  }

  /**
   * Remove establishment from favorites
   */
  async removeFavorite(userId, establishmentId) {
    const favorite = await Favorite.findOne({
      where: { user_id: userId, establishment_id: establishmentId },
    });

    if (!favorite) {
      throw ApiError.notFound("Favorite not found");
    }

    await favorite.destroy();

    // Decrement establishment favorites count
    await Establishment.decrement("total_favorites", {
      where: { id: establishmentId },
    });

    return { message: "Favorite removed successfully" };
  }

  /**
   * Toggle favorite (add if not exists, remove if exists)
   */
  async toggleFavorite(userId, establishmentId) {
    // Check if establishment exists and is active
    const establishment = await Establishment.findOne({
      where: { id: establishmentId, status: "active" },
    });

    if (!establishment) {
      throw ApiError.notFound("Establishment not found");
    }

    // Check if already favorited
    const existingFavorite = await Favorite.findOne({
      where: { user_id: userId, establishment_id: establishmentId },
    });

    if (existingFavorite) {
      // Remove favorite
      await existingFavorite.destroy();
      await establishment.decrement("total_favorites");

      return {
        action: "removed",
        is_favorited: false,
        message: "Removed from favorites",
      };
    } else {
      // Add favorite
      const favorite = await Favorite.create({
        user_id: userId,
        establishment_id: establishmentId,
      });
      await establishment.increment("total_favorites");

      return {
        action: "added",
        is_favorited: true,
        favorite_id: favorite.id,
        message: "Added to favorites",
      };
    }
  }

  /**
   * Check if establishment is favorited by user
   */
  async isFavorited(userId, establishmentId) {
    const favorite = await Favorite.findOne({
      where: { user_id: userId, establishment_id: establishmentId },
    });

    return {
      is_favorited: !!favorite,
      favorite_id: favorite ? favorite.id : null,
    };
  }

  /**
   * Check multiple establishments favorite status
   */
  async checkMultipleFavorites(userId, establishmentIds) {
    const favorites = await Favorite.findAll({
      where: {
        user_id: userId,
        establishment_id: { [Op.in]: establishmentIds },
      },
      attributes: ["establishment_id"],
    });

    const favoritedIds = favorites.map((f) => f.establishment_id);

    return establishmentIds.reduce((acc, id) => {
      acc[id] = favoritedIds.includes(id);
      return acc;
    }, {});
  }

  /**
   * Get user's favorites count
   */
  async getFavoritesCount(userId) {
    const count = await Favorite.count({
      where: { user_id: userId },
    });

    return { count };
  }

  /**
   * Clear all favorites
   */
  async clearAllFavorites(userId) {
    const favorites = await Favorite.findAll({
      where: { user_id: userId },
      attributes: ["establishment_id"],
    });

    const establishmentIds = favorites.map((f) => f.establishment_id);

    // Delete all favorites
    await Favorite.destroy({
      where: { user_id: userId },
    });

    // Decrement favorites count for all establishments
    if (establishmentIds.length > 0) {
      await Establishment.decrement("total_favorites", {
        where: { id: { [Op.in]: establishmentIds } },
      });
    }

    return {
      message: "All favorites cleared",
      removed_count: establishmentIds.length,
    };
  }
}

module.exports = new FavoriteService();
