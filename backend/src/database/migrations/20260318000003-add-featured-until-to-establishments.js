"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const [results] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'establishments' AND column_name = 'featured_until'`
    );
    if (results.length === 0) {
      await queryInterface.addColumn("establishments", "featured_until", {
        type: Sequelize.DATE,
        allowNull: true,
        defaultValue: null,
        comment: "Date d'expiration de la mise en avant (null = sans limite)",
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("establishments", "featured_until");
  },
};
