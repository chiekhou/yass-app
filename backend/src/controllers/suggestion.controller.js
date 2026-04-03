const suggestionService = require("../services/suggestion.service");
const { ApiResponse } = require("../utils");

class SuggestionController {
  // ==================== USER ROUTES ====================

  /**
   * Soumettre une suggestion
   * POST /api/v1/suggestions
   */
  async create(req, res, next) {
    try {
      const suggestion = await suggestionService.create(req.userId, req.body);
      ApiResponse.created(
        suggestion,
        "Suggestion soumise avec succès"
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Liste des suggestions en attente (public, triées par votes)
   * GET /api/v1/suggestions
   */
  async getAll(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
      };
      const result = await suggestionService.getAll(req.userId || null, options);
      result.send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Mes suggestions
   * GET /api/v1/suggestions/mine
   */
  async getMine(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
      };
      const result = await suggestionService.getMySuggestions(req.userId, options);
      result.send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Voter pour une suggestion
   * POST /api/v1/suggestions/:id/vote
   */
  async vote(req, res, next) {
    try {
      const result = await suggestionService.vote(req.userId, req.params.id);
      ApiResponse.success(result, result.voted ? "Recommandation ajoutée" : "Recommandation retirée").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Voter contre une suggestion
   * POST /api/v1/suggestions/:id/downvote
   */
  async downvote(req, res, next) {
    try {
      const result = await suggestionService.downvote(req.userId, req.params.id);
      ApiResponse.success(
        result,
        result.downvoted ? "Vote contre ajouté" : "Vote contre retiré"
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  // ==================== ADMIN ROUTES ====================

  /**
   * Liste admin de toutes les suggestions
   * GET /api/v1/admin/suggestions
   */
  async adminGetAll(req, res, next) {
    try {
      const options = {
        page: parseInt(req.query.page) || 1,
        limit: parseInt(req.query.limit) || 20,
        status: req.query.status || undefined,
      };
      const result = await suggestionService.adminGetAll(options);
      result.send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Approuver une suggestion
   * POST /api/v1/admin/suggestions/:id/approve
   */
  async adminApprove(req, res, next) {
    try {
      const suggestion = await suggestionService.adminApprove(
        req.params.id,
        req.userId
      );
      ApiResponse.success(suggestion, "Suggestion approuvée").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Rejeter une suggestion
   * POST /api/v1/admin/suggestions/:id/reject
   */
  async adminReject(req, res, next) {
    try {
      const { note } = req.body;
      const suggestion = await suggestionService.adminReject(
        req.params.id,
        req.userId,
        note
      );
      ApiResponse.success(suggestion, "Suggestion rejetée").send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SuggestionController();
