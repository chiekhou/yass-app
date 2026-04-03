"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    // Type de facture : abonnement ou mise à la une
    await queryInterface.addColumn("invoices", "type", {
      type: Sequelize.ENUM("subscription", "featured"),
      allowNull: false,
      defaultValue: "subscription",
    });

    // Établissement concerné (pour les factures featured)
    await queryInterface.addColumn("invoices", "establishment_id", {
      type: Sequelize.UUID,
      allowNull: true,
      references: { model: "establishments", key: "id" },
      onDelete: "SET NULL",
    });

    // Durée de mise à la une (ex: 7, 15, 30)
    await queryInterface.addColumn("invoices", "featured_duration_days", {
      type: Sequelize.INTEGER,
      allowNull: true,
    });

    // Plan featured — PostgreSQL requires ALTER TYPE to add enum values
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_invoices_plan" ADD VALUE IF NOT EXISTS 'featured_7'`
    );
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_invoices_plan" ADD VALUE IF NOT EXISTS 'featured_15'`
    );
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_invoices_plan" ADD VALUE IF NOT EXISTS 'featured_30'`
    );
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn("invoices", "featured_duration_days");
    await queryInterface.removeColumn("invoices", "establishment_id");
    await queryInterface.removeColumn("invoices", "type");
    await queryInterface.changeColumn("invoices", "plan", {
      type: Sequelize.ENUM("monthly", "yearly"),
      allowNull: false,
    });
  },
};
