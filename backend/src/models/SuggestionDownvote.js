const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const SuggestionDownvote = sequelize.define(
    "SuggestionDownvote",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      suggestion_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: "establishment_suggestions", key: "id" },
      },
      user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: { model: "users", key: "id" },
      },
    },
    {
      tableName: "suggestion_downvotes",
      timestamps: true,
      underscored: true,
      indexes: [
        {
          unique: true,
          fields: ["suggestion_id", "user_id"],
          name: "unique_suggestion_downvote",
        },
      ],
    }
  );

  SuggestionDownvote.associate = (models) => {
    SuggestionDownvote.belongsTo(models.EstablishmentSuggestion, {
      foreignKey: "suggestion_id",
      as: "suggestion",
    });
    SuggestionDownvote.belongsTo(models.User, {
      foreignKey: "user_id",
      as: "user",
    });
  };

  return SuggestionDownvote;
};
