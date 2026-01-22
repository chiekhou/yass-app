const fs = require("fs");
const path = require("path");
const sharp = require("sharp");
const ApiError = require("../utils/ApiError");

class UploadService {
  constructor() {
    this.baseUrl = process.env.BASE_URL || "http://localhost:3000";
  }

  /**
   * Get full URL for a file path
   */
  getFileUrl(filePath) {
    if (!filePath) return null;
    if (filePath.startsWith("http")) return filePath;
    return `${this.baseUrl}/${filePath.replace(/\\/g, "/")}`;
  }

  /**
   * Process and optimize image
   */
  async processImage(file, options = {}) {
    const {
      width = null,
      height = null,
      quality = 80,
      format = "webp",
    } = options;

    const inputPath = file.path;
    const outputDir = path.dirname(inputPath);
    const outputFilename = `${path.basename(inputPath, path.extname(inputPath))}.${format}`;
    const outputPath = path.join(outputDir, outputFilename);

    try {
      let sharpInstance = sharp(inputPath);

      // Resize if dimensions provided
      if (width || height) {
        sharpInstance = sharpInstance.resize(width, height, {
          fit: "cover",
          withoutEnlargement: true,
        });
      }

      // Convert and optimize
      if (format === "webp") {
        sharpInstance = sharpInstance.webp({ quality });
      } else if (format === "jpeg" || format === "jpg") {
        sharpInstance = sharpInstance.jpeg({ quality });
      } else if (format === "png") {
        sharpInstance = sharpInstance.png({ quality });
      }

      await sharpInstance.toFile(outputPath);

      // Delete original if different from output
      if (inputPath !== outputPath) {
        fs.unlinkSync(inputPath);
      }

      return {
        filename: outputFilename,
        path: outputPath.replace(process.cwd() + path.sep, ""),
        url: this.getFileUrl(outputPath.replace(process.cwd() + path.sep, "")),
      };
    } catch (error) {
      // Clean up on error
      if (fs.existsSync(inputPath)) {
        fs.unlinkSync(inputPath);
      }
      throw new ApiError(500, "Error processing image: " + error.message);
    }
  }

  /**
   * Process avatar image
   */
  async processAvatar(file) {
    return this.processImage(file, {
      width: 200,
      height: 200,
      quality: 85,
      format: "webp",
    });
  }

  /**
   * Process establishment logo
   */
  async processLogo(file) {
    return this.processImage(file, {
      width: 400,
      height: 400,
      quality: 85,
      format: "webp",
    });
  }

  /**
   * Process establishment cover image
   */
  async processCover(file) {
    return this.processImage(file, {
      width: 1200,
      height: 600,
      quality: 85,
      format: "webp",
    });
  }

  /**
   * Process gallery image
   */
  async processGalleryImage(file) {
    return this.processImage(file, {
      width: 1200,
      height: null, // Keep aspect ratio
      quality: 85,
      format: "webp",
    });
  }

  /**
   * Process review image
   */
  async processReviewImage(file) {
    return this.processImage(file, {
      width: 800,
      height: null,
      quality: 80,
      format: "webp",
    });
  }

  /**
   * Process multiple gallery images
   */
  async processGalleryImages(files) {
    const processed = [];
    for (const file of files) {
      const result = await this.processGalleryImage(file);
      processed.push(result);
    }
    return processed;
  }

  /**
   * Process multiple review images
   */
  async processReviewImages(files) {
    const processed = [];
    for (const file of files) {
      const result = await this.processReviewImage(file);
      processed.push(result);
    }
    return processed;
  }

  /**
   * Delete file
   */
  deleteFile(filePath) {
    try {
      if (!filePath) return;

      // Handle both relative and absolute paths
      const fullPath = filePath.startsWith("/")
        ? filePath
        : path.join(process.cwd(), filePath);

      if (fs.existsSync(fullPath)) {
        fs.unlinkSync(fullPath);
        return true;
      }
      return false;
    } catch (error) {
      console.error("Error deleting file:", error.message);
      return false;
    }
  }

  /**
   * Delete multiple files
   */
  deleteFiles(filePaths) {
    if (!Array.isArray(filePaths)) return;
    filePaths.forEach((filePath) => this.deleteFile(filePath));
  }

  /**
   * Extract filename from URL
   */
  getFilenameFromUrl(url) {
    if (!url) return null;
    const parts = url.split("/");
    return parts[parts.length - 1];
  }

  /**
   * Get file path from URL
   */
  getFilePathFromUrl(url) {
    if (!url) return null;
    if (!url.startsWith(this.baseUrl)) return null;
    return url.replace(this.baseUrl + "/", "");
  }
}

module.exports = new UploadService();
