"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn("partners", "stripe_customer_id", {
      type: Sequelize.STRING(255),
      allowNull: true,
    });

    await queryInterface.addColumn("partners", "stripe_subscription_id", {
      type: Sequelize.STRING(255),
      allowNull: true,
    });

    await queryInterface.addColumn("partners", "trial_ends_at", {
      type: Sequelize.DATE,
      allowNull: true,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("partners", "stripe_customer_id");
    await queryInterface.removeColumn("partners", "stripe_subscription_id");
    await queryInterface.removeColumn("partners", "trial_ends_at");
  },
};
