require("dotenv").config();

module.exports = {
  development: {
    username: process.env.DB_USER || "yass_app_user",
    password: process.env.DB_PASSWORD || "yass_app_password_2025",
    database: process.env.DB_NAME || "annuaire_dz",
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 5432,
    dialect: "postgres",
    logging: console.log,
    define: {
      timestamps: true,
      underscored: true,
      underscoredAll: true,
      createdAt: "created_at",
      updatedAt: "updated_at",
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
  },
  test: {
    username: process.env.DB_USER || "yass_app_user",
    password: process.env.DB_PASSWORD || "yass_app_password_2025",
    database: process.env.DB_NAME || "annuaire_dz",
    port: process.env.DB_PORT || 5432,
    dialect: "postgres",
    logging: false,
    define: {
      timestamps: true,
      underscored: true,
      underscoredAll: true,
      createdAt: "created_at",
      updatedAt: "updated_at",
    },
  },
  production: {
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    dialect: "postgres",
    logging: false,
    define: {
      timestamps: true,
      underscored: true,
      underscoredAll: true,
      createdAt: "created_at",
      updatedAt: "updated_at",
    },
    pool: {
      max: 20,
      min: 5,
      acquire: 30000,
      idle: 10000,
    },
    dialectOptions: {
      ssl: {
        require: true,
        rejectUnauthorized: false,
      },
    },
  },
};
