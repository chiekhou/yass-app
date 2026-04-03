const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const EstablishmentSuggestion = sequelize.define(
    "EstablishmentSuggestion",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      name: {
        type: DataTypes.STRING(255),
        allowNull: false,
      },
      address: {
        type: DataTypes.TEXT,
        allowNull: false,
      },
      phone: {
        type: DataTypes.STRING(50),
        allowNull: true,
      },
      description: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      contact_email: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      reason: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      category_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: { model: "categories", key: "id" },
      },
      wilaya_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: { model: "wilayas", key: "id" },
      },
      suggested_by: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: "users", key: "id" },
      },
      vote_count: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 1,
      },
      downvote_count: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0,
      },
      status: {
        type: DataTypes.ENUM("pending", "approved", "rejected"),
        allowNull: false,
        defaultValue: "pending",
      },
      admin_note: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      reviewed_by: {
        type: DataTypes.UUID,
        allowNull: true,
        references: { model: "users", key: "id" },
      },
      reviewed_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
    },
    {
      tableName: "establishment_suggestions",
      timestamps: true,
      underscored: true,
      indexes: [
        { fields: ["status"] },
        { fields: ["suggested_by"] },
        { fields: ["vote_count"] },
      ],
    }
  );

  EstablishmentSuggestion.associate = (models) => {
    EstablishmentSuggestion.belongsTo(models.User, {
      foreignKey: "suggested_by",
      as: "suggester",
    });
    EstablishmentSuggestion.belongsTo(models.Category, {
      foreignKey: "category_id",
      as: "category",
    });
    EstablishmentSuggestion.belongsTo(models.Wilaya, {
      foreignKey: "wilaya_id",
      as: "wilaya",
    });
    EstablishmentSuggestion.belongsTo(models.User, {
      foreignKey: "reviewed_by",
      as: "reviewer",
    });
    EstablishmentSuggestion.hasMany(models.SuggestionVote, {
      foreignKey: "suggestion_id",
      as: "votes",
    });
    EstablishmentSuggestion.hasMany(models.SuggestionDownvote, {
      foreignKey: "suggestion_id",
      as: "downvotes",
    });
  };

  return EstablishmentSuggestion;
};
