const express = require("express");
const router = express.Router();
const categoryController = require("../controllers/category.controller");

/**
 * @route   GET /api/v1/subcategories/slug/:slug
 * @desc    Get subcategory by slug
 * @access  Public
 */
router.get("/slug/:slug", categoryController.getSubcategoryBySlug);

/**
 * @route   GET /api/v1/subcategories/:id
 * @desc    Get subcategory by ID
 * @access  Public
 */
router.get("/:id", categoryController.getSubcategoryById);

module.exports = router;
