const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const SuggestionVote = sequelize.define(
    "SuggestionVote",
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
      tableName: "suggestion_votes",
      timestamps: true,
      underscored: true,
      indexes: [
        {
          unique: true,
          fields: ["suggestion_id", "user_id"],
          name: "unique_suggestion_vote",
        },
      ],
    }
  );

  SuggestionVote.associate = (models) => {
    SuggestionVote.belongsTo(models.EstablishmentSuggestion, {
      foreignKey: "suggestion_id",
      as: "suggestion",
    });
    SuggestionVote.belongsTo(models.User, {
      foreignKey: "user_id",
      as: "user",
    });
  };

  return SuggestionVote;
};
