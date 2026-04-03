const { DataTypes } = require("sequelize");

module.exports = (sequelize) => {
  const Invoice = sequelize.define(
    "Invoice",
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      invoice_number: {
        type: DataTypes.STRING(50),
        allowNull: false,
        unique: true,
      },
      partner_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: "partners",
          key: "id",
        },
      },
      type: {
        type: DataTypes.ENUM("subscription", "featured"),
        allowNull: false,
        defaultValue: "subscription",
      },
      plan: {
        type: DataTypes.ENUM("monthly", "yearly", "featured_7", "featured_15", "featured_30"),
        allowNull: false,
      },
      establishment_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: { model: "establishments", key: "id" },
      },
      featured_duration_days: {
        type: DataTypes.INTEGER,
        allowNull: true,
        comment: "Durée de la mise à la une en jours",
      },
      amount: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: false,
      },
      currency: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: "DZD",
      },
      payment_method: {
        type: DataTypes.ENUM("chargily", "manual", "cash"),
        allowNull: false,
      },
      status: {
        type: DataTypes.ENUM("pending_validation", "paid", "failed", "cancelled"),
        allowNull: false,
        defaultValue: "pending_validation",
      },
      chargily_checkout_id: {
        type: DataTypes.STRING(255),
        allowNull: true,
      },
      chargily_checkout_url: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      transfer_reference: {
        type: DataTypes.STRING(255),
        allowNull: true,
        comment: "Référence du virement pour paiement manuel",
      },
      period_start: {
        type: DataTypes.DATEONLY,
        allowNull: true,
      },
      period_end: {
        type: DataTypes.DATEONLY,
        allowNull: true,
      },
      notes: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      paid_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      validated_by: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "users",
          key: "id",
        },
      },
      validated_at: {
        type: DataTypes.DATE,
        allowNull: true,
      },
    },
    {
      tableName: "invoices",
      timestamps: true,
      underscored: true,
    }
  );

  Invoice.associate = (models) => {
    Invoice.belongsTo(models.Partner, {
      foreignKey: "partner_id",
      as: "partner",
    });
    Invoice.belongsTo(models.User, {
      foreignKey: "validated_by",
      as: "validator",
    });
    Invoice.belongsTo(models.Establishment, {
      foreignKey: "establishment_id",
      as: "establishment",
    });
  };

  return Invoice;
};
