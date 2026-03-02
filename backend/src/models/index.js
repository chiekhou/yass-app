const { Sequelize } = require("sequelize");
const config = require("../config/database");

const env = process.env.NODE_ENV || "development";
const dbConfig = config[env];

// Initialize Sequelize
const sequelize = new Sequelize(
  dbConfig.database,
  dbConfig.username,
  dbConfig.password,
  {
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: dbConfig.dialect,
    logging: dbConfig.logging,
    define: dbConfig.define,
    pool: dbConfig.pool,
    dialectOptions: dbConfig.dialectOptions,
  }
);

// Import models
const User = require("./User")(sequelize);
const Wilaya = require("./Wilaya")(sequelize);
const Commune = require("./Commune")(sequelize);
const Category = require("./Category")(sequelize);
const SubCategory = require("./Subcategory")(sequelize);
const Partner = require("./Partner")(sequelize);
const Establishment = require("./Establishment")(sequelize);
const Review = require("./Review")(sequelize);
const Favorite = require("./Favorite")(sequelize);
const Promotion = require("./Promotion")(sequelize);
const RefreshToken = require("./RefreshToken")(sequelize);
const Invoice = require("./Invoice")(sequelize);
const Notification = require("./Notification")(sequelize);

// Create models object
const models = {
  User,
  Wilaya,
  Commune,
  Category,
  SubCategory,
  Partner,
  Establishment,
  Review,
  Favorite,
  Promotion,
  RefreshToken,
  Invoice,
  Notification,
};

// Run associations
Object.keys(models).forEach((modelName) => {
  if (models[modelName].associate) {
    models[modelName].associate(models);
  }
});

// Export
module.exports = {
  sequelize,
  Sequelize,
  ...models,
};
