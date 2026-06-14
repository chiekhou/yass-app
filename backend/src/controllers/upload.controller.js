const uploadService = require("../services/upload.service");
const { User, Establishment } = require("../models");
const { ApiResponse } = require("../utils");
const ApiError = require("../utils/ApiError");

class UploadController {
  /**
   * Upload user avatar
   * POST /api/v1/upload/avatar
   */
  async uploadAvatar(req, res, next) {
    try {
      if (!req.file) {
        throw new ApiError(400, "No file uploaded");
      }

      // Process the image
      const processed = await uploadService.processAvatar(req.file);

      // Get current user
      const user = await User.findByPk(req.userId);

      // Delete old avatar if exists
      if (user.avatar) {
        uploadService.deleteFile(uploadService.getFilePathFromUrl(user.avatar));
      }

      // Update user avatar
      await user.update({ avatar: processed.url });

      ApiResponse.success(
        {
          avatar: processed.url,
        },
        "Avatar uploaded successfully",
      ).send(res);
    } catch (error) {
      // Clean up uploaded file on error
      if (req.file) {
        uploadService.deleteFile(req.file.path);
      }
      next(error);
    }
  }

  /**
   * Delete user avatar
   * DELETE /api/v1/upload/avatar
   */
  async deleteAvatar(req, res, next) {
    try {
      const user = await User.findByPk(req.userId);

      if (user.avatar) {
        uploadService.deleteFile(uploadService.getFilePathFromUrl(user.avatar));
        await user.update({ avatar: null });
      }

      ApiResponse.success(null, "Avatar deleted successfully").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Upload establishment logo
   * POST /api/v1/partner/establishments/:id/logo
   */
  async uploadLogo(req, res, next) {
    try {
      if (!req.file) {
        throw new ApiError(400, "No file uploaded");
      }

      const { id } = req.params;

      // Check ownership
      const establishment = await Establishment.findOne({
        where: { id, partner_id: req.partnerId },
      });

      if (!establishment) {
        throw new ApiError(404, "Establishment not found");
      }

      // Process the image
      const processed = await uploadService.processLogo(req.file);

      // Delete old logo if exists
      if (establishment.logo) {
        uploadService.deleteFile(
          uploadService.getFilePathFromUrl(establishment.logo),
        );
      }

      // Update establishment logo
      await establishment.update({ logo: processed.url });

      ApiResponse.success(
        {
          logo: processed.url,
        },
        "Logo uploaded successfully",
      ).send(res);
    } catch (error) {
      if (req.file) {
        uploadService.deleteFile(req.file.path);
      }
      next(error);
    }
  }

  /**
   * Upload establishment cover
   * POST /api/v1/partner/establishments/:id/cover
   */
  async uploadCover(req, res, next) {
    try {
      if (!req.file) {
        throw new ApiError(400, "No file uploaded");
      }

      const { id } = req.params;

      // Check ownership
      const establishment = await Establishment.findOne({
        where: { id, partner_id: req.partnerId },
      });

      if (!establishment) {
        throw new ApiError(404, "Establishment not found");
      }

      // Process the image
      const processed = await uploadService.processCover(req.file);

      // Delete old cover if exists
      if (establishment.cover_image) {
        uploadService.deleteFile(
          uploadService.getFilePathFromUrl(establishment.cover_image),
        );
      }

      // Update establishment cover
      await establishment.update({ cover_image: processed.url });

      ApiResponse.success(
        {
          cover_image: processed.url,
        },
        "Cover image uploaded successfully",
      ).send(res);
    } catch (error) {
      if (req.file) {
        uploadService.deleteFile(req.file.path);
      }
      next(error);
    }
  }

  /**
   * Upload establishment gallery images
   * POST /api/v1/partner/establishments/:id/gallery
   */
  async uploadGallery(req, res, next) {
    try {
      if (!req.files || req.files.length === 0) {
        throw new ApiError(400, "No files uploaded");
      }

      const { id } = req.params;

      // Check ownership
      const establishment = await Establishment.findOne({
        where: { id, partner_id: req.partnerId },
      });

      if (!establishment) {
        throw new ApiError(404, "Establishment not found");
      }

      // Process all images
      const processed = await uploadService.processGalleryImages(req.files);

      // Get current images
      const currentImages = establishment.images || [];

      // Check total limit (max 20 images)
      if (currentImages.length + processed.length > 20) {
        // Clean up uploaded files
        processed.forEach((p) => uploadService.deleteFile(p.path));
        throw new ApiError(
          400,
          "Maximum 20 images allowed. You have " +
            currentImages.length +
            " images.",
        );
      }

      // Add new images to gallery
      const newImages = [...currentImages, ...processed.map((p) => p.url)];
      await establishment.update({ images: newImages });

      ApiResponse.success(
        {
          images: newImages,
          uploaded: processed.map((p) => p.url),
        },
        "Images uploaded successfully",
      ).send(res);
    } catch (error) {
      // Clean up uploaded files on error
      if (req.files) {
        req.files.forEach((file) => uploadService.deleteFile(file.path));
      }
      next(error);
    }
  }

  /**
   * Delete gallery image
   * DELETE /api/v1/partner/establishments/:id/gallery
   */
  async deleteGalleryImage(req, res, next) {
    try {
      const { id } = req.params;
      const { image_url } = req.body;

      if (!image_url) {
        throw new ApiError(400, "Image URL is required");
      }

      // Check ownership
      const establishment = await Establishment.findOne({
        where: { id, partner_id: req.partnerId },
      });

      if (!establishment) {
        throw new ApiError(404, "Establishment not found");
      }

      // Remove image from array
      const currentImages = establishment.images || [];
      const newImages = currentImages.filter((img) => img !== image_url);

      if (currentImages.length === newImages.length) {
        throw new ApiError(404, "Image not found in gallery");
      }

      // Delete file
      uploadService.deleteFile(uploadService.getFilePathFromUrl(image_url));

      // Update establishment
      await establishment.update({ images: newImages });

      ApiResponse.success(
        {
          images: newImages,
        },
        "Image deleted successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Upload review images
   * POST /api/v1/upload/review-images
   */
  async uploadReviewImages(req, res, next) {
    try {
      if (!req.files || req.files.length === 0) {
        throw new ApiError(400, "No files uploaded");
      }

      const processed = await uploadService.processReviewImages(req.files);
      const urls = processed.map((p) => p.url);

      ApiResponse.success(
        { images: urls },
        "Images uploaded successfully",
      ).send(res);
    } catch (error) {
      if (req.files) {
        req.files.forEach((file) => uploadService.deleteFile(file.path));
      }
      next(error);
    }
  }

  /**
   * Upload review videos
   * POST /api/v1/upload/review-videos
   */
  async uploadReviewVideos(req, res, next) {
    try {
      if (!req.files || req.files.length === 0) {
        throw new ApiError(400, "No files uploaded");
      }

      const processed = await uploadService.processReviewVideos(req.files);
      const urls = processed.map((p) => p.url);

      ApiResponse.success(
        { videos: urls },
        "Videos uploaded successfully",
      ).send(res);
    } catch (error) {
      if (req.files) {
        req.files.forEach((file) => uploadService.deleteFile(file.path));
      }
      next(error);
    }
  }

  /**
   * Reorder gallery images
   * PUT /api/v1/partner/establishments/:id/gallery/reorder
   */
  async reorderGallery(req, res, next) {
    try {
      const { id } = req.params;
      const { images } = req.body;

      if (!Array.isArray(images)) {
        throw new ApiError(400, "Images array is required");
      }

      // Check ownership
      const establishment = await Establishment.findOne({
        where: { id, partner_id: req.partnerId },
      });

      if (!establishment) {
        throw new ApiError(404, "Establishment not found");
      }

      // Verify all images exist in current gallery
      const currentImages = establishment.images || [];
      const isValid = images.every((img) => currentImages.includes(img));

      if (!isValid || images.length !== currentImages.length) {
        throw new ApiError(400, "Invalid images array");
      }

      // Update order
      await establishment.update({ images });

      ApiResponse.success(
        {
          images,
        },
        "Gallery reordered successfully",
      ).send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UploadController();
