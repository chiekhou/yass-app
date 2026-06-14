const multer = require("multer");
const path = require("path");
const fs = require("fs");
const ApiError = require("../utils/ApiError");

// Ensure upload directories exist
const uploadDirs = [
  "uploads",
  "uploads/avatars",
  "uploads/establishments",
  "uploads/establishments/logos",
  "uploads/establishments/covers",
  "uploads/establishments/gallery",
  "uploads/reviews",
  "uploads/reviews/videos",
];

uploadDirs.forEach((dir) => {
  const fullPath = path.join(process.cwd(), dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
});

// Allowed file types
const ALLOWED_TYPES = {
  image: ["image/jpeg", "image/jpg", "image/png", "image/webp"],
  document: ["application/pdf"],
  video: ["video/mp4", "video/quicktime", "video/x-msvideo", "video/webm"],
};

// Max file sizes (in bytes)
const MAX_SIZES = {
  avatar: 2 * 1024 * 1024,   // 2MB
  logo: 2 * 1024 * 1024,     // 2MB
  cover: 5 * 1024 * 1024,    // 5MB
  gallery: 5 * 1024 * 1024,  // 5MB
  review: 5 * 1024 * 1024,   // 5MB
  reviewVideo: 50 * 1024 * 1024, // 50MB
};

/**
 * Create multer storage configuration
 */
const createStorage = (destination) => {
  return multer.diskStorage({
    destination: (req, file, cb) => {
      cb(null, destination);
    },
    filename: (req, file, cb) => {
      const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
      const ext = path.extname(file.originalname).toLowerCase();
      cb(null, `${uniqueSuffix}${ext}`);
    },
  });
};

/**
 * File filter for images
 */
const imageFilter = (req, file, cb) => {
  if (ALLOWED_TYPES.image.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new ApiError(400, "Only JPEG, PNG and WebP images are allowed"), false);
  }
};

/**
 * Create multer upload middleware
 */
const createUploader = (destination, maxSize, fieldName = "file") => {
  return multer({
    storage: createStorage(destination),
    limits: {
      fileSize: maxSize,
    },
    fileFilter: imageFilter,
  });
};

// ==================== UPLOAD CONFIGURATIONS ====================

/**
 * Avatar upload (single file)
 */
const avatarUpload = createUploader(
  path.join(process.cwd(), "uploads/avatars"),
  MAX_SIZES.avatar,
).single("avatar");

/**
 * Establishment logo upload (single file)
 */
const logoUpload = createUploader(
  path.join(process.cwd(), "uploads/establishments/logos"),
  MAX_SIZES.logo,
).single("logo");

/**
 * Establishment cover upload (single file)
 */
const coverUpload = createUploader(
  path.join(process.cwd(), "uploads/establishments/covers"),
  MAX_SIZES.cover,
).single("cover");

/**
 * Establishment gallery upload (multiple files, max 10)
 */
const galleryUpload = createUploader(
  path.join(process.cwd(), "uploads/establishments/gallery"),
  MAX_SIZES.gallery,
).array("images", 10);

/**
 * Review images upload (multiple files, max 5)
 */
const reviewImagesUpload = createUploader(
  path.join(process.cwd(), "uploads/reviews"),
  MAX_SIZES.review,
).array("images", 5);

/**
 * File filter for videos
 */
const videoFilter = (req, file, cb) => {
  if (ALLOWED_TYPES.video.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new ApiError(400, "Only MP4, MOV, AVI and WebM videos are allowed"), false);
  }
};

/**
 * Middleware wrapper to handle multer errors
 */
const handleUpload = (uploadMiddleware) => {
  return (req, res, next) => {
    uploadMiddleware(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === "LIMIT_FILE_SIZE") {
          return next(new ApiError(400, "File too large"));
        }
        if (err.code === "LIMIT_FILE_COUNT") {
          return next(new ApiError(400, "Too many files"));
        }
        if (err.code === "LIMIT_UNEXPECTED_FILE") {
          return next(new ApiError(400, "Unexpected field name"));
        }
        return next(new ApiError(400, err.message));
      } else if (err) {
        return next(err);
      }
      next();
    });
  };
};

/**
 * Review videos upload (multiple files, max 3, 50MB each)
 */
const reviewVideosUpload = handleUpload(
  multer({
    storage: createStorage(path.join(process.cwd(), "uploads/reviews/videos")),
    limits: { fileSize: MAX_SIZES.reviewVideo },
    fileFilter: videoFilter,
  }).array("videos", 3),
);

module.exports = {
  avatarUpload: handleUpload(avatarUpload),
  logoUpload: handleUpload(logoUpload),
  coverUpload: handleUpload(coverUpload),
  galleryUpload: handleUpload(galleryUpload),
  reviewImagesUpload: handleUpload(reviewImagesUpload),
  reviewVideosUpload,
  ALLOWED_TYPES,
  MAX_SIZES,
};
