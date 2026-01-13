const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Review = sequelize.define(
    "Review",
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
      rating: {
        type: DataTypes.INTEGER,
        allowNull: false,
        validate: {
          min: 1,
          max: 5,
        },
      },
      title: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      comment: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      images: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: [],
      },
      status: {
        type: DataTypes.ENUM("pending", "approved", "rejected", "hidden"),
        defaultValue: "approved",
      },
      is_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        comment: "True if user actually visited the establishment",
      },
      partner_reply: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      partner_reply_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      helpful_count: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      report_count: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
      },
      moderated_by: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "users",
          key: "id",
        },
      },
      moderated_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      rejection_reason: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
    },
    {
      tableName: "reviews",
      timestamps: true,
      underscored: true,
      indexes: [
        {
          unique: true,
          fields: ["user_id", "establishment_id"],
          name: "unique_user_establishment_review",
        },
        { fields: ["establishment_id"] },
        { fields: ["status"] },
        { fields: ["rating"] },
      ],
    }
  );

  Review.associate = (models) => {
    Review.belongsTo(models.User, {
      foreignKey: "user_id",
      as: "user",
    });
    Review.belongsTo(models.Establishment, {
      foreignKey: "establishment_id",
      as: "establishment",
    });
    Review.belongsTo(models.User, {
      foreignKey: "moderated_by",
      as: "moderator",
    });
  };

  return Review;
};
