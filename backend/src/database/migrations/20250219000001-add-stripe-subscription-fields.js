"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const col = async (column) => {
      const [r] = await queryInterface.sequelize.query(
        `SELECT 1 FROM information_schema.columns WHERE table_name = 'partners' AND column_name = '${column}'`
      );
      return r.length > 0;
    };

    if (!(await col("stripe_customer_id"))) {
      await queryInterface.addColumn("partners", "stripe_customer_id", {
        type: Sequelize.STRING(255),
        allowNull: true,
      });
    }

    if (!(await col("stripe_subscription_id"))) {
      await queryInterface.addColumn("partners", "stripe_subscription_id", {
        type: Sequelize.STRING(255),
        allowNull: true,
      });
    }

    if (!(await col("trial_ends_at"))) {
      await queryInterface.addColumn("partners", "trial_ends_at", {
        type: Sequelize.DATE,
        allowNull: true,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("partners", "stripe_customer_id");
    await queryInterface.removeColumn("partners", "stripe_subscription_id");
    await queryInterface.removeColumn("partners", "trial_ends_at");
  },
};
