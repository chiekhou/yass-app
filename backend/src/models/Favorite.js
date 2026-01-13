const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Favorite = sequelize.define(
    "Favorite",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "users",
          key: "id",
        },
      },
      establishment_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "establishments",
          key: "id",
        },
      },
    },
    {
      tableName: "favorites",
      timestamps: true,
      underscored: true,
      indexes: [
        {
          unique: true,
          fields: ["user_id", "establishment_id"],
          name: "unique_user_establishment_favorite",
        },
      ],
    }
  );

  Favorite.associate = (models) => {
    Favorite.belongsTo(models.User, {
      foreignKey: "user_id",
      as: "user",
    });
    Favorite.belongsTo(models.Establishment, {
      foreignKey: "establishment_id",
      as: "establishment",
    });
  };

  return Favorite;
};
