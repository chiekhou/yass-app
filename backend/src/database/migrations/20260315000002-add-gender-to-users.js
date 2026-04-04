"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const [results] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'gender'`
    );
    if (results.length === 0) {
      await queryInterface.addColumn("users", "gender", {
        type: Sequelize.ENUM("male", "female", "young", "child"),
        allowNull: true,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("users", "gender");
    await queryInterface.sequelize.query(
      'DROP TYPE IF EXISTS "enum_users_gender";'
    );
  },
};
