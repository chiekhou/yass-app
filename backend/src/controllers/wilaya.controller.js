const wilayaService = require("../services/wilaya.service");
const { ApiResponse } = require("../utils");
const ApiError = require("../utils/ApiError");

class WilayaController {
  /**
   * Get all wilayas
   * GET /api/v1/wilayas
   */
  async getAll(req, res, next) {
    try {
      const { communes } = req.query;
      const includeCommunes = communes === "true" || communes === "1";

      const wilayas = await wilayaService.getAllWilayas({
        includeCommunes,
        activeOnly: true,
      });

      if (!wilayas || wilayas.length === 0) {
        return ApiResponse.success([], "No wilayas found").send(res);
      }

      ApiResponse.success(wilayas, "Wilayas retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get wilaya by ID
   * GET /api/v1/wilayas/:id
   */
  async getById(req, res, next) {
    try {
      const { id } = req.params;

      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!id || !uuidRegex.test(id)) {
        throw ApiError.badRequest("Invalid wilaya ID");
      }

      const wilaya = await wilayaService.getWilayaById(id, {
        includeCommunes: true,
      });

      ApiResponse.success(wilaya, "Wilaya retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get wilaya by code
   * GET /api/v1/wilayas/code/:code
   */
  async getByCode(req, res, next) {
    try {
      const { code } = req.params;

      if (!code || code.trim() === "") {
        throw ApiError.badRequest("Wilaya code is required");
      }

      const wilaya = await wilayaService.getWilayaByCode(code.trim(), {
        includeCommunes: true,
      });

      ApiResponse.success(wilaya, "Wilaya retrieved successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get communes by wilaya
   * GET /api/v1/wilayas/:id/communes
   */
  async getCommunes(req, res, next) {
    try {
      const { id } = req.params;

      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!id || !uuidRegex.test(id)) {
        throw ApiError.badRequest("Invalid wilaya ID");
      }

      const communes = await wilayaService.getCommunesByWilaya(id);

      if (!communes || communes.length === 0) {
        return ApiResponse.success(
          [],
          "No communes found for this wilaya",
        ).send(res);
      }

      ApiResponse.success(communes, "Communes retrieved successfully").send(
        res,
      );
    } catch (error) {
      next(error);
    }
  }

  /**
   * Search wilayas
   * GET /api/v1/wilayas/search?q=alger
   */
  async search(req, res, next) {
    try {
      const { q } = req.query;

      if (!q || q.trim() === "") {
        return ApiResponse.success([], "Search query is required").send(res);
      }

      if (q.trim().length < 2) {
        return ApiResponse.success(
          [],
          "Search query must be at least 2 characters",
        ).send(res);
      }

      const wilayas = await wilayaService.searchWilayas(q.trim());

      if (!wilayas || wilayas.length === 0) {
        return ApiResponse.success(
          [],
          "No wilayas found matching your search",
        ).send(res);
      }

      ApiResponse.success(wilayas, "Search results").send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new WilayaController();
