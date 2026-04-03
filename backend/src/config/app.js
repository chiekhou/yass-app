require("dotenv").config();

module.exports = {
  // Server
  env: process.env.NODE_ENV || "development",
  port: parseInt(process.env.PORT, 10) || 3000,
  apiVersion: process.env.API_VERSION || "v1",

  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || "default_secret_change_me",
    expiresIn: process.env.JWT_EXPIRES_IN || "7d",
    refreshSecret: process.env.JWT_REFRESH_SECRET || "default_refresh_secret",
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "30d",
  },

  // Bcrypt
  bcrypt: {
    saltRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS, 10) || 12,
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS, 10) || 15 * 60 * 1000, // 15 minutes
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
  },

  // File Upload
  upload: {
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE, 10) || 5 * 1024 * 1024, // 5MB
    path: process.env.UPLOAD_PATH || "./uploads",
    allowedMimeTypes: ["image/jpeg", "image/png", "image/gif", "image/webp"],
  },

  // Cloudinary
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    apiSecret: process.env.CLOUDINARY_API_SECRET,
  },

  // Firebase
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  },

  // URLs
  urls: {
    app: process.env.APP_URL || "http://localhost:3000",
    frontend: process.env.FRONTEND_URL || "http://localhost:8080",
  },

  // Email
  email: {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT, 10) || 587,
    user: process.env.SMTP_USER,
    password: process.env.SMTP_PASSWORD,
    from: process.env.EMAIL_FROM || "noreply@annuaire-dz.com",
  },

  // Twilio SMS
  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    phoneNumber: process.env.TWILIO_PHONE_NUMBER,
  },

  // Chargily Pay
  chargily: {
    apiKey: process.env.CHARGILY_API_KEY || "",
    mode: process.env.CHARGILY_MODE || "test", // 'test' | 'live'
    trialDays: 14,
    plans: {
      monthly: { amount: 2000, days: 30, label: "Mensuel" },
      yearly: { amount: 18000, days: 365, label: "Annuel" },
    },
    featuredPlans: {
      featured_7:  { amount: 500,  days: 7,  label: "7 jours" },
      featured_15: { amount: 800,  days: 15, label: "15 jours" },
      featured_30: { amount: 1400, days: 30, label: "30 jours" },
    },
    bankDetails: {
      ccp: process.env.BANK_CCP || "0012345678 clé 12",
      rib: process.env.BANK_RIB || "00200 00001 0000000000 12",
      accountName: "Win-وين",
    },
  },

  // Pagination defaults
  pagination: {
    defaultLimit: 20,
    maxLimit: 100,
  },

  // Supported languages
  languages: ["fr", "ar", "en"],
  defaultLanguage: "fr",

  // Supported wilayas (will be expanded)
  wilayas: [
    { code: "16", name: "Alger", name_ar: "الجزائر" },
    { code: "31", name: "Oran", name_ar: "وهران" },
    { code: "25", name: "Constantine", name_ar: "قسنطينة" },
    { code: "23", name: "Annaba", name_ar: "عنابة" },
    { code: "15", name: "Tizi Ouzou", name_ar: "تيزي وزو" },
  ],
};
