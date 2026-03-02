"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn("users", "email_otp", {
      type: Sequelize.STRING(6),
      allowNull: true,
    });

    await queryInterface.addColumn("users", "email_otp_expires", {
      type: Sequelize.DATE,
      allowNull: true,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("users", "email_otp");
    await queryInterface.removeColumn("users", "email_otp_expires");
  },
};
