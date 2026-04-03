"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn("users", "gender", {
      type: Sequelize.ENUM("male", "female", "young", "child"),
      allowNull: true,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("users", "gender");
    await queryInterface.sequelize.query(
      'DROP TYPE IF EXISTS "enum_users_gender";'
    );
  },
};
