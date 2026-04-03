const express = require("express");
const router = express.Router();
const suggestionController = require("../controllers/suggestion.controller");
const { authenticate } = require("../middlewares/auth");

/**
 * @route   POST /api/v1/suggestions
 * @desc    Soumettre une suggestion d'établissement
 * @access  Private
 */
router.post("/", authenticate, suggestionController.create);

/**
 * @route   GET /api/v1/suggestions
 * @desc    Liste des suggestions en attente (triées par votes)
 * @access  Private (userId pour savoir si on a voté)
 */
router.get("/", authenticate, suggestionController.getAll);

/**
 * @route   GET /api/v1/suggestions/mine
 * @desc    Mes suggestions soumises
 * @access  Private
 */
router.get("/mine", authenticate, suggestionController.getMine);

/**
 * @route   POST /api/v1/suggestions/:id/vote
 * @desc    Voter / retirer son vote pour une suggestion
 * @access  Private
 */
router.post("/:id/vote", authenticate, suggestionController.vote);

/**
 * @route   POST /api/v1/suggestions/:id/downvote
 * @desc    Voter contre / retirer son vote contre pour une suggestion
 * @access  Private
 */
router.post("/:id/downvote", authenticate, suggestionController.downvote);

module.exports = router;
