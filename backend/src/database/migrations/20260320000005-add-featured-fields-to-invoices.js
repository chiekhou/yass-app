"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const col = async (column) => {
      const [r] = await queryInterface.sequelize.query(
        `SELECT 1 FROM information_schema.columns WHERE table_name = 'invoices' AND column_name = '${column}'`
      );
      return r.length > 0;
    };

    if (!(await col("type"))) {
      await queryInterface.addColumn("invoices", "type", {
        type: Sequelize.ENUM("subscription", "featured"),
        allowNull: false,
        defaultValue: "subscription",
      });
    }

    if (!(await col("establishment_id"))) {
      await queryInterface.addColumn("invoices", "establishment_id", {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: "establishments", key: "id" },
        onDelete: "SET NULL",
      });
    }

    if (!(await col("featured_duration_days"))) {
      await queryInterface.addColumn("invoices", "featured_duration_days", {
        type: Sequelize.INTEGER,
        allowNull: true,
      });
    }

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
