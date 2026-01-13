const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Wilaya = sequelize.define(
    "Wilaya",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      code: {
        type: DataTypes.STRING(5),
        allowNull: false,
        unique: true,
      },
      name: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      name_ar: {
        type: DataTypes.STRING(100),
        allowNull: false,
      },
      name_en: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      latitude: {
        type: DataTypes.DECIMAL(10, 8),
        allowNull: true,
      },
      longitude: {
        type: DataTypes.DECIMAL(11, 8),
        allowNull: true,
      },
      is_active: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
      },
      order: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
    },
    {
      tableName: "wilayas",
      timestamps: true,
      underscored: true,
    }
  );

  Wilaya.associate = (models) => {
    Wilaya.hasMany(models.Commune, {
      foreignKey: "wilaya_id",
      as: "communes",
    });
    Wilaya.hasMany(models.Establishment, {
      foreignKey: "wilaya_id",
      as: "establishments",
    });
    Wilaya.hasMany(models.User, {
      foreignKey: "wilaya_id",
      as: "users",
    });
  };

  return Wilaya;
};
