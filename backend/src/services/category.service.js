const { Category, SubCategory, Establishment } = require("../models");
const ApiError = require("../utils/ApiError");
const { Op } = require("sequelize");

class CategoryService {
  /**
   * Get all active categories
   */
  async getAllCategories(options = {}) {
    const {
      includeSubcategories = false,
      activeOnly = true,
      withCount = false,
    } = options;

    const where = {};
    if (activeOnly) {
      where.is_active = true;
    }

    const include = [];
    if (includeSubcategories) {
      include.push({
        model: SubCategory,
        as: "subcategories",
        where: activeOnly ? { is_active: true } : {},
        required: false,
        attributes: [
          "id",
          "name",
          "name_ar",
          "name_en",
          "slug",
          "icon",
          "image",
          "order",
        ],
        order: [["order", "ASC"]],
      });
    }

    const categories = await Category.findAll({
      where,
      include,
      order: [
        ["order", "ASC"],
        ["name", "ASC"],
      ],
      attributes: [
        "id",
        "name",
        "name_ar",
        "name_en",
        "slug",
        "description",
        "description_ar",
        "icon",
        "image",
        "color",
        "order",
      ],
    });

    // Add establishment count if requested
    if (withCount) {
      const categoriesWithCount = await Promise.all(
        categories.map(async (category) => {
          const count = await Establishment.count({
            where: {
              category_id: category.id,
              status: "active",
            },
          });
          return {
            ...category.toJSON(),
            establishments_count: count,
          };
        }),
      );
      return categoriesWithCount;
    }

    return categories;
  }

  /**
   * Get category by ID
   */
  async getCategoryById(id, options = {}) {
    const { includeSubcategories = true } = options;

    const include = [];
    if (includeSubcategories) {
      include.push({
        model: SubCategory,
        as: "subcategories",
        where: { is_active: true },
        required: false,
        attributes: [
          "id",
          "name",
          "name_ar",
          "name_en",
          "slug",
          "description",
          "description_ar",
          "icon",
          "image",
          "order",
        ],
        order: [["order", "ASC"]],
      });
    }

    const category = await Category.findByPk(id, {
      include,
      attributes: [
        "id",
        "name",
        "name_ar",
        "name_en",
        "slug",
        "description",
        "description_ar",
        "icon",
        "image",
        "color",
        "order",
      ],
    });

    if (!category) {
      throw ApiError.notFound("Category not found");
    }

    return category;
  }

  /**
   * Get category by slug
   */
  async getCategoryBySlug(slug, options = {}) {
    const { includeSubcategories = true } = options;

    const include = [];
    if (includeSubcategories) {
      include.push({
        model: SubCategory,
        as: "subcategories",
        where: { is_active: true },
        required: false,
        attributes: [
          "id",
          "name",
          "name_ar",
          "name_en",
          "slug",
          "description",
          "description_ar",
          "icon",
          "image",
          "order",
        ],
        order: [["order", "ASC"]],
      });
    }

    const category = await Category.findOne({
      where: { slug, is_active: true },
      include,
      attributes: [
        "id",
        "name",
        "name_ar",
        "name_en",
        "slug",
        "description",
        "description_ar",
        "icon",
        "image",
        "color",
        "order",
      ],
    });

    if (!category) {
      throw ApiError.notFound("Category not found");
    }

    return category;
  }

  /**
   * Get subcategories by category ID
   */
  async getSubcategoriesByCategory(categoryId) {
    const category = await Category.findByPk(categoryId);

    if (!category) {
      throw ApiError.notFound("Category not found");
    }

    const subcategories = await SubCategory.findAll({
      where: {
        category_id: categoryId,
        is_active: true,
      },
      attributes: [
        "id",
        "name",
        "name_ar",
        "name_en",
        "slug",
        "description",
        "description_ar",
        "icon",
        "image",
        "order",
      ],
      order: [
        ["order", "ASC"],
        ["name", "ASC"],
      ],
    });

    return subcategories;
  }

  /**
   * Get subcategory by ID
   */
  async getSubcategoryById(id) {
    const subcategory = await SubCategory.findByPk(id, {
      include: [
        {
          model: Category,
          as: "category",
          attributes: ["id", "name", "name_ar", "slug"],
        },
      ],
      attributes: [
        "id",
        "name",
        "name_ar",
        "name_en",
        "slug",
        "description",
        "description_ar",
        "icon",
        "image",
        "order",
      ],
    });

    if (!subcategory) {
      throw ApiError.notFound("Subcategory not found");
    }

    return subcategory;
  }

  /**
   * Get subcategory by slug
   */
  async getSubcategoryBySlug(slug) {
    const subcategory = await SubCategory.findOne({
      where: { slug, is_active: true },
      include: [
        {
          model: Category,
          as: "category",
          attributes: ["id", "name", "name_ar", "slug"],
        },
      ],
      attributes: [
        "id",
        "name",
        "name_ar",
        "name_en",
        "slug",
        "description",
        "description_ar",
        "icon",
        "image",
        "order",
      ],
    });

    if (!subcategory) {
      throw ApiError.notFound("Subcategory not found");
    }

    return subcategory;
  }

  /**
   * Search categories and subcategories
   */
  async searchCategories(query) {
    const categories = await Category.findAll({
      where: {
        is_active: true,
        [Op.or]: [
          { name: { [Op.iLike]: `%${query}%` } },
          { name_ar: { [Op.iLike]: `%${query}%` } },
        ],
      },
      attributes: ["id", "name", "name_ar", "slug", "icon", "color"],
      limit: 5,
    });

    const subcategories = await SubCategory.findAll({
      where: {
        is_active: true,
        [Op.or]: [
          { name: { [Op.iLike]: `%${query}%` } },
          { name_ar: { [Op.iLike]: `%${query}%` } },
        ],
      },
      include: [
        {
          model: Category,
          as: "category",
          attributes: ["id", "name", "slug"],
        },
      ],
      attributes: ["id", "name", "name_ar", "slug", "icon"],
      limit: 5,
    });

    return {
      categories,
      subcategories,
    };
  }
}

module.exports = new CategoryService();
