const express = require("express");
const router = express.Router();
const categoryController = require("../controllers/category.controller");

/**
 * @route   GET /api/v1/categories
 * @desc    Get all categories
 * @access  Public
 * @query   subcategories=true - Include subcategories in response
 * @query   count=true - Include establishment count
 */
router.get("/", categoryController.getAll);

/**
 * @route   GET /api/v1/categories/search
 * @desc    Search categories and subcategories
 * @access  Public
 * @query   q - Search query (min 2 characters)
 */
router.get("/search", categoryController.search);

/**
 * @route   GET /api/v1/categories/slug/:slug
 * @desc    Get category by slug
 * @access  Public
 */
router.get("/slug/:slug", categoryController.getBySlug);

/**
 * @route   GET /api/v1/categories/:id
 * @desc    Get category by ID
 * @access  Public
 */
router.get("/:id", categoryController.getById);

/**
 * @route   GET /api/v1/categories/:id/subcategories
 * @desc    Get subcategories by category ID
 * @access  Public
 */
router.get("/:id/subcategories", categoryController.getSubcategories);

module.exports = router;
