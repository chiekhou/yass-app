const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Partner = sequelize.define(
    "Partner",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        unique: true,
        references: {
          model: "users",
          key: "id",
        },
      },
      company_name: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      registration_number: {
        type: DataTypes.STRING(100),
        allowNull: true,
        comment: "Numéro de registre de commerce",
      },
      tax_id: {
        type: DataTypes.STRING(100),
        allowNull: true,
        comment: "NIF - Numéro d'identification fiscale",
      },
      status: {
        type: DataTypes.ENUM("pending", "approved", "rejected", "suspended"),
        defaultValue: "pending",
      },
      subscription_plan: {
        type: DataTypes.ENUM("free", "premium", "gold"),
        defaultValue: "free",
      },
      subscription_expires_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      chargily_checkout_id: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      trial_ends_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      documents: {
        type: DataTypes.JSONB,
        allowNull: true,
        defaultValue: [],
        comment: "Array of uploaded documents (registre commerce, etc.)",
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
      notes: {
        type: DataTypes.TEXT,
        allowNull: true,
        comment: "Notes internes admin",
      },
    },
    {
      tableName: "partners",
      timestamps: true,
      underscored: true,
    }
  );

  Partner.associate = (models) => {
    Partner.belongsTo(models.User, {
      foreignKey: "user_id",
      as: "user",
    });
    Partner.belongsTo(models.User, {
      foreignKey: "verified_by",
      as: "verifier",
    });
    Partner.hasMany(models.Establishment, {
      foreignKey: "partner_id",
      as: "establishments",
    });
    Partner.hasMany(models.Invoice, {
      foreignKey: "partner_id",
      as: "invoices",
    });
  };

  return Partner;
};
