const express = require("express");
const router = express.Router();
const uploadController = require("../controllers/upload.controller");
const { authenticate } = require("../middlewares/auth");
const { avatarUpload } = require("../config/upload");

// All upload routes require authentication
router.use(authenticate);

/**
 * @route   POST /api/v1/upload/avatar
 * @desc    Upload user avatar
 * @access  Private
 * @body    FormData with 'avatar' field
 */
router.post("/avatar", avatarUpload, uploadController.uploadAvatar);

/**
 * @route   DELETE /api/v1/upload/avatar
 * @desc    Delete user avatar
 * @access  Private
 */
router.delete("/avatar", uploadController.deleteAvatar);

module.exports = router;
