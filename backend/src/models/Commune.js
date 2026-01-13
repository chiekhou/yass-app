const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Commune = sequelize.define(
    "Commune",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      wilaya_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "wilayas",
          key: "id",
        },
      },
      code: {
        type: DataTypes.STRING(10),
        allowNull: false,
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
      postal_code: {
        type: DataTypes.STRING(10),
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
    },
    {
      tableName: "communes",
      timestamps: true,
      underscored: true,
      indexes: [
        {
          unique: true,
          fields: ["wilaya_id", "code"],
        },
      ],
    }
  );

  Commune.associate = (models) => {
    Commune.belongsTo(models.Wilaya, {
      foreignKey: "wilaya_id",
      as: "wilaya",
    });
    Commune.hasMany(models.Establishment, {
      foreignKey: "commune_id",
      as: "establishments",
    });
  };

  return Commune;
};
