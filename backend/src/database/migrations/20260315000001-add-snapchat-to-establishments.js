"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const [results] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'establishments' AND column_name = 'snapchat'`
    );
    if (results.length === 0) {
      await queryInterface.addColumn("establishments", "snapchat", {
        type: Sequelize.STRING(500),
        allowNull: true,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("Establishments", "snapchat");
  },
};
