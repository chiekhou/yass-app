const express = require("express");
const router = express.Router();
const wilayaController = require("../controllers/wilaya.controller");

/**
 * @route   GET /api/v1/wilayas
 * @desc    Get all wilayas
 * @access  Public
 * @query   communes=true - Include communes in response
 */
router.get("/", wilayaController.getAll);

/**
 * @route   GET /api/v1/wilayas/search
 * @desc    Search wilayas by name
 * @access  Public
 * @query   q - Search query (min 2 characters)
 */
router.get("/search", wilayaController.search);

/**
 * @route   GET /api/v1/wilayas/code/:code
 * @desc    Get wilaya by code (01-58)
 * @access  Public
 */
router.get("/code/:code", wilayaController.getByCode);

/**
 * @route   GET /api/v1/wilayas/:id
 * @desc    Get wilaya by ID
 * @access  Public
 */
router.get("/:id", wilayaController.getById);

/**
 * @route   GET /api/v1/wilayas/:id/communes
 * @desc    Get communes by wilaya ID
 * @access  Public
 */
router.get("/:id/communes", wilayaController.getCommunes);

module.exports = router;
