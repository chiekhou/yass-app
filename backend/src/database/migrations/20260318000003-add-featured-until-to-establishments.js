"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn("establishments", "featured_until", {
      type: Sequelize.DATE,
      allowNull: true,
      defaultValue: null,
      comment: "Date d'expiration de la mise en avant (null = sans limite)",
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("establishments", "featured_until");
  },
};
