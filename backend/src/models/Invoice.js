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
      plan: {
        type: DataTypes.ENUM("monthly", "yearly"),
        allowNull: false,
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
        type: DataTypes.ENUM("chargily", "manual"),
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
  };

  return Invoice;
};
