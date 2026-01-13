const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Promotion = sequelize.define(
    "Promotion",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      establishment_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "establishments",
          key: "id",
        },
      },
      title: {
        type: DataTypes.STRING(255),
        allowNull: false,
      },
      title_ar: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      description: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      description_ar: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      type: {
        type: DataTypes.ENUM(
          "percentage",
          "fixed",
          "buy_one_get_one",
          "free_item",
          "other"
        ),
        defaultValue: "percentage",
      },
      discount_value: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
        comment: "Percentage or fixed amount",
      },
      promo_code: {
        type: DataTypes.STRING(50),
        allowNull: true,
      },
      image: {
        type: DataTypes.STRING(500),
        allowNull: true,
      },
      terms: {
        type: DataTypes.TEXT,
        allowNull: true,
        comment: "Terms and conditions",
      },
      start_date: {
        type: DataTypes.DATE,
        allowNull: false,
      },
      end_date: {
        type: DataTypes.DATE,
        allowNull: false,
      },
      max_uses: {
        type: DataTypes.INTEGER,
        allowNull: true,
        comment: "Maximum number of uses, null = unlimited",
      },
      current_uses: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      status: {
        type: DataTypes.ENUM(
          "draft",
          "pending",
          "active",
          "paused",
          "expired",
          "rejected"
        ),
        defaultValue: "pending",
      },
      is_featured: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      total_views: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      approved_by: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "users",
          key: "id",
        },
      },
      approved_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      rejection_reason: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
    },
    {
      tableName: "promotions",
      timestamps: true,
      underscored: true,
      indexes: [
        { fields: ["establishment_id"] },
        { fields: ["status"] },
        { fields: ["start_date", "end_date"] },
        { fields: ["is_featured"] },
      ],
    }
  );

  Promotion.associate = (models) => {
    Promotion.belongsTo(models.Establishment, {
      foreignKey: "establishment_id",
      as: "establishment",
    });
    Promotion.belongsTo(models.User, {
      foreignKey: "approved_by",
      as: "approver",
    });
  };

  return Promotion;
};
