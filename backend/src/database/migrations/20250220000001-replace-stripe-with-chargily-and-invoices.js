"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    // 1. Supprimer les champs Stripe de la table partners
    await queryInterface.removeColumn("partners", "stripe_customer_id");
    await queryInterface.removeColumn("partners", "stripe_subscription_id");

    // 2. Ajouter le champ Chargily à la table partners
    await queryInterface.addColumn("partners", "chargily_checkout_id", {
      type: Sequelize.STRING(255),
      allowNull: true,
      after: "trial_ends_at",
    });

    // 3. Créer la table invoices
    await queryInterface.createTable("invoices", {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      invoice_number: {
        type: Sequelize.STRING(50),
        allowNull: false,
        unique: true,
      },
      partner_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: "partners", key: "id" },
        onDelete: "CASCADE",
        onUpdate: "CASCADE",
      },
      plan: {
        type: Sequelize.ENUM("monthly", "yearly"),
        allowNull: false,
      },
      amount: {
        type: Sequelize.DECIMAL(10, 2),
        allowNull: false,
      },
      currency: {
        type: Sequelize.STRING(10),
        allowNull: false,
        defaultValue: "DZD",
      },
      payment_method: {
        type: Sequelize.ENUM("chargily", "manual"),
        allowNull: false,
      },
      status: {
        type: Sequelize.ENUM("pending_validation", "paid", "failed", "cancelled"),
        allowNull: false,
        defaultValue: "pending_validation",
      },
      chargily_checkout_id: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      chargily_checkout_url: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      transfer_reference: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      period_start: {
        type: Sequelize.DATEONLY,
        allowNull: true,
      },
      period_end: {
        type: Sequelize.DATEONLY,
        allowNull: true,
      },
      notes: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      paid_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      validated_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: "users", key: "id" },
        onDelete: "SET NULL",
        onUpdate: "CASCADE",
      },
      validated_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal("CURRENT_TIMESTAMP"),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal("CURRENT_TIMESTAMP"),
      },
    });

    // 4. Index pour les requêtes fréquentes
    await queryInterface.addIndex("invoices", ["partner_id"]);
    await queryInterface.addIndex("invoices", ["status"]);
    await queryInterface.addIndex("invoices", ["payment_method", "status"]);
  },

  async down(queryInterface, Sequelize) {
    // Supprimer la table invoices
    await queryInterface.dropTable("invoices");

    // Supprimer le champ Chargily
    await queryInterface.removeColumn("partners", "chargily_checkout_id");

    // Remettre les champs Stripe
    await queryInterface.addColumn("partners", "stripe_customer_id", {
      type: Sequelize.STRING(255),
      allowNull: true,
    });
    await queryInterface.addColumn("partners", "stripe_subscription_id", {
      type: Sequelize.STRING(255),
      allowNull: true,
    });
  },
};
