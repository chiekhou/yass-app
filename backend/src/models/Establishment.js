const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Establishment = sequelize.define(
    "Establishment",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      partner_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "partners",
          key: "id",
        },
      },
      category_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "categories",
          key: "id",
        },
      },
      subcategory_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "subcategories",
          key: "id",
        },
      },
      wilaya_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "wilayas",
          key: "id",
        },
      },
      commune_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "communes",
          key: "id",
        },
      },
      name: {
        type: DataTypes.STRING(255),
        allowNull: false,
      },
      name_ar: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      slug: {
        type: DataTypes.STRING(280),
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
      address: {
        type: DataTypes.STRING(500),
        allowNull: false,
      },
      address_ar: {
        type: DataTypes.STRING(500),
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
      phone: {
        type: DataTypes.STRING(20),
        allowNull: true,
      },
      phone_secondary: {
        type: DataTypes.STRING(20),
        allowNull: true,
      },
      whatsapp: {
        type: DataTypes.STRING(20),
        allowNull: true,
      },
      email: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      website: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      facebook: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      instagram: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      tiktok: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      snapchat: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      logo: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      cover_image: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      images: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: [],
      },
      opening_hours: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: {},
        comment: "JSON object with days and hours",
      },
      price_range: {
        type: DataTypes.ENUM("$", "$$", "$$$", "$$$$"),
        allowNull: true,
      },
      services: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: [],
        comment: "List of services offered",
      },
      amenities: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: [],
        comment: "WiFi, Parking, AC, etc.",
      },
      tags: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: [],
      },
      status: {
        type: DataTypes.ENUM(
          "pending",
          "active",
          "inactive",
          "rejected",
          "suspended"
        ),
        defaultValue: "pending",
      },
      is_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      is_featured: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      featured_until: {
        type: DataTypes.DATE,
        allowNull: true,
        defaultValue: null,
        comment: "Date d'expiration de la mise en avant (null = sans limite)",
      },
      average_rating: {
        type: DataTypes.DECIMAL(3, 2),
        defaultValue: 0,
      },
      total_reviews: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      total_views: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      total_favorites: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      total_calls: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      total_whatsapp_clicks: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      total_contacts: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      verified_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      verified_by: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "users",
          key: "id",
        },
      },
      rejection_reason: {
        type: DataTypes.TEXT,
        allowNull: true,
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
      tableName: "establishments",
      timestamps: true,
      underscored: true,
      indexes: [
        { fields: ["status"] },
        { fields: ["category_id"] },
        { fields: ["subcategory_id"] },
        { fields: ["wilaya_id"] },
        { fields: ["commune_id"] },
        { fields: ["is_featured"] },
        { fields: ["average_rating"] },
        { fields: ["latitude", "longitude"] },
      ],
    }
  );

  Establishment.associate = (models) => {
    Establishment.belongsTo(models.Partner, {
      foreignKey: "partner_id",
      as: "partner",
    });
    Establishment.belongsTo(models.Category, {
      foreignKey: "category_id",
      as: "category",
    });
    Establishment.belongsTo(models.SubCategory, {
      foreignKey: "subcategory_id",
      as: "subcategory",
    });
    Establishment.belongsTo(models.Wilaya, {
      foreignKey: "wilaya_id",
      as: "wilaya",
    });
    Establishment.belongsTo(models.Commune, {
      foreignKey: "commune_id",
      as: "commune",
    });
    Establishment.belongsTo(models.User, {
      foreignKey: "verified_by",
      as: "verifier",
    });
    Establishment.hasMany(models.Review, {
      foreignKey: "establishment_id",
      as: "reviews",
    });
    Establishment.hasMany(models.Favorite, {
      foreignKey: "establishment_id",
      as: "favorites",
    });
    Establishment.hasMany(models.Promotion, {
      foreignKey: "establishment_id",
      as: "promotions",
    });
  };

  return Establishment;
};
