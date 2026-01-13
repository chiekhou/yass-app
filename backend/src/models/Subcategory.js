const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const SubCategory = sequelize.define(
    "SubCategory",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      category_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "categories",
          key: "id",
        },
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
      slug: {
        type: DataTypes.STRING(120),
        allowNull: false,
        unique: true,
      },
      description: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      description_ar: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      icon: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      image: {
        type: DataTypes.STRING(500),
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
      tableName: "subcategories",
      timestamps: true,
      underscored: true,
    }
  );

  SubCategory.associate = (models) => {
    SubCategory.belongsTo(models.Category, {
      foreignKey: "category_id",
      as: "category",
    });
    SubCategory.hasMany(models.Establishment, {
      foreignKey: "subcategory_id",
      as: "establishments",
    });
  };

  return SubCategory;
};
