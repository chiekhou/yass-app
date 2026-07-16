const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Category = sequelize.define(
    "Category",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
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
      name_de: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      name_es: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      name_it: {
        type: DataTypes.STRING(100),
        allowNull: true,
      },
      name_nl: {
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
      color: {
        type: DataTypes.STRING(20),
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
      meta_title: {
        type: DataTypes.STRING(200),
        allowNull: true,
      },
      meta_description: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
    },
    {
      tableName: "categories",
      timestamps: true,
      underscored: true,
    }
  );

  Category.associate = (models) => {
    Category.hasMany(models.SubCategory, {
      foreignKey: "category_id",
      as: "subcategories",
    });
    Category.hasMany(models.Establishment, {
      foreignKey: "category_id",
      as: "establishments",
    });
  };

  return Category;
};
