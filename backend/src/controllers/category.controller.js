const categoryService = require("../services/category.service");
const { ApiResponse } = require("../utils");
const ApiError = require("../utils/ApiError");

class CategoryController {
  /**
   * Get all categories
   * GET /api/v1/categories
   */
  async getAll(req, res, next) {
    try {
      const { subcategories, count } = req.query;
      const includeSubcategories =
        subcategories === "true" || subcategories === "1";
      const withCount = count === "true" || count === "1";

      const categories = await categoryService.getAllCategories({
        includeSubcategories,
        activeOnly: true,
        withCount,
      });

      if (!categories || categories.length === 0) {
        return ApiResponse.success([], "No categories found").send(res);
      }

      ApiResponse.success(categories, "Categories retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get category by ID
   * GET /api/v1/categories/:id
   */
  async getById(req, res, next) {
    try {
      const { id } = req.params;

      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!id || !uuidRegex.test(id)) {
        throw ApiError.badRequest("Invalid category ID");
      }

      const category = await categoryService.getCategoryById(id, {
        includeSubcategories: true,
      });

      ApiResponse.success(category, "Category retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get category by slug
   * GET /api/v1/categories/slug/:slug
   */
  async getBySlug(req, res, next) {
    try {
      const { slug } = req.params;

      if (!slug || slug.trim() === "") {
        throw ApiError.badRequest("Category slug is required");
      }

      const category = await categoryService.getCategoryBySlug(slug.trim(), {
        includeSubcategories: true,
      });

      ApiResponse.success(category, "Category retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get subcategories by category
   * GET /api/v1/categories/:id/subcategories
   */
  async getSubcategories(req, res, next) {
    try {
      const { id } = req.params;

      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!id || !uuidRegex.test(id)) {
        throw ApiError.badRequest("Invalid category ID");
      }

      const subcategories =
        await categoryService.getSubcategoriesByCategory(id);

      if (!subcategories || subcategories.length === 0) {
        return ApiResponse.success(
          [],
          "No subcategories found for this category",
        ).send(res);
      }

      ApiResponse.success(
        subcategories,
        "Subcategories retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get subcategory by ID
   * GET /api/v1/subcategories/:id
   */
  async getSubcategoryById(req, res, next) {
    try {
      const { id } = req.params;

      if (!id || isNaN(parseInt(id))) {
        throw ApiError.badRequest("Invalid subcategory ID");
      }

      const subcategory = await categoryService.getSubcategoryById(id);

      ApiResponse.success(
        subcategory,
        "Subcategory retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get subcategory by slug
   * GET /api/v1/subcategories/slug/:slug
   */
  async getSubcategoryBySlug(req, res, next) {
    try {
      const { slug } = req.params;

      if (!slug || slug.trim() === "") {
        throw ApiError.badRequest("Subcategory slug is required");
      }

      const subcategory = await categoryService.getSubcategoryBySlug(
        slug.trim(),
      );

      ApiResponse.success(
        subcategory,
        "Subcategory retrieved successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Search categories
   * GET /api/v1/categories/search?q=restaurant
   */
  async search(req, res, next) {
    try {
      const { q } = req.query;

      if (!q || q.trim() === "") {
        return ApiResponse.success(
          { categories: [], subcategories: [] },
          "Search query is required",
        ).send(res);
      }

      if (q.trim().length < 2) {
        return ApiResponse.success(
          { categories: [], subcategories: [] },
          "Search query must be at least 2 characters",
        ).send(res);
      }

      const results = await categoryService.searchCategories(q.trim());

      if (
        (!results.categories || results.categories.length === 0) &&
        (!results.subcategories || results.subcategories.length === 0)
      ) {
        return ApiResponse.success(
          { categories: [], subcategories: [] },
          "No categories or subcategories found matching your search",
        ).send(res);
      }

      ApiResponse.success(results, "Search results").send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CategoryController();
