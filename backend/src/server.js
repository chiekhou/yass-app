require("dotenv").config();

const app = require("./app");
const config = require("./config/app");
const { sequelize } = require("./models");

const PORT = config.port;

// Database connection and server start
const startServer = async () => {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log("✅ Database connection established successfully.");

    // Sync models (in development only)
    if (config.env === "development") {
      await sequelize.sync({ alter: true });
      console.log("✅ Database models synchronized.");
    }

    // Start server
    app.listen(PORT, () => {
      console.log(`
╔═══════════════════════════════════════════════════╗
║                                                   ║
║   🚀 Server is running!                           ║
║                                                   ║
║   Environment: ${config.env.padEnd(33)}║
║   Port: ${PORT.toString().padEnd(40)}║
║   API: http://localhost:${PORT}/api/${config.apiVersion}             ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error("❌ Unable to start server:", error.message);
    process.exit(1);
  }
};

// Handle unhandled promise rejections
process.on("unhandledRejection", (reason, promise) => {
  console.error("Unhandled Rejection at:", promise, "reason:", reason);
});

// Handle uncaught exceptions
process.on("uncaughtException", (error) => {
  console.error("Uncaught Exception:", error);
  process.exit(1);
});

// Graceful shutdown
process.on("SIGTERM", async () => {
  console.log("SIGTERM received. Shutting down gracefully...");
  await sequelize.close();
  process.exit(0);
});

process.on("SIGINT", async () => {
  console.log("SIGINT received. Shutting down gracefully...");
  await sequelize.close();
  process.exit(0);
});

// Start the server
startServer();
