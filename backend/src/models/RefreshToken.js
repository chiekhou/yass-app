const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const RefreshToken = sequelize.define(
    "RefreshToken",
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
      token: {
        type: DataTypes.STRING(500),
        allowNull: false,
        unique: true,
      },
      expires_at: {
        type: DataTypes.DATE,
        allowNull: false,
      },
      device_info: {
        type: DataTypes.JSONB,
        allowNull: true,
        comment: "Device name, OS, app version, etc.",
      },
      ip_address: {
        type: DataTypes.STRING(50),
        allowNull: true,
      },
      is_revoked: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      revoked_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
    },
    {
      tableName: "refresh_tokens",
      timestamps: true,
      underscored: true,
      indexes: [
        { fields: ["token"] },
        { fields: ["user_id"] },
        { fields: ["expires_at"] },
      ],
    }
  );

  RefreshToken.associate = (models) => {
    RefreshToken.belongsTo(models.User, {
      foreignKey: "user_id",
      as: "user",
    });
  };

  return RefreshToken;
};
