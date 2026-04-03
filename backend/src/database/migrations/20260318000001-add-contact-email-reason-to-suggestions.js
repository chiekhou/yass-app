"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn("establishment_suggestions", "contact_email", {
      type: Sequelize.STRING(255),
      allowNull: true,
    });
    await queryInterface.addColumn("establishment_suggestions", "reason", {
      type: Sequelize.TEXT,
      allowNull: true,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("establishment_suggestions", "contact_email");
    await queryInterface.removeColumn("establishment_suggestions", "reason");
  },
};
