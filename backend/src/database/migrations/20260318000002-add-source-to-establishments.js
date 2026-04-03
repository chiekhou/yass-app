"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn("establishments", "source", {
      type: Sequelize.STRING(50),
      allowNull: true,
      defaultValue: "manual",
      comment: "Origine de la donnée: manual, osm, import...",
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("establishments", "source");
  },
};
