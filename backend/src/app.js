const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const path = require("path");

const config = require("./config/app");
const routes = require("./routes");
const subscriptionController = require("./controllers/subscription.controller");
const {
  errorConverter,
  errorHandler,
  notFound,
  sequelizeErrorHandler,
  generalLimiter,
} = require("./middlewares");

// Initialize express app
const app = express();

// Trust proxy (for rate limiting behind reverse proxy)
app.set("trust proxy", 1);

// Public pages — served before helmet to avoid CSP blocking inline styles/scripts
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});
app.get("/support", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/support.html"));
});
app.get("/privacy", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/privacy.html"));
});
app.get("/delete-data", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/delete-data.html"));
});

// Security middleware
app.use(helmet());

// CORS configuration
app.use(
  cors({
    // Mobile app clients don't send Origin headers — CORS only matters for
    // browser-based tools (admin panel, webhooks tested via browser, etc.).
    // In production we allow the server's own domain; in dev we allow all.
    origin: config.env === "production"
      ? [config.urls.app, ...(process.env.ALLOWED_ORIGINS || "").split(",").filter(Boolean)]
      : "*",
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Accept-Language"],
  })
);

// Request logging
if (config.env === "development") {
  app.use(morgan("dev"));
} else {
  app.use(morgan("combined"));
}

// Chargily webhook — must be registered BEFORE body parsers (needs raw body)
app.post(
  `/api/${config.apiVersion}/chargily/webhook`,
  express.raw({ type: "application/json" }),
  subscriptionController.webhook
);

// Body parsing
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Static files (uploads)
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));

// Rate limiting
app.use(generalLimiter);

// API routes
app.use(`/api/${config.apiVersion}`, routes);

// Root route
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Welcome to Annuaire DZ API",
    version: config.apiVersion,
    documentation: `/api/${config.apiVersion}/docs`,
  });
});

// Handle 404
app.use(notFound);

// Error handling
app.use(sequelizeErrorHandler);
app.use(errorConverter);
app.use(errorHandler);

module.exports = app;
