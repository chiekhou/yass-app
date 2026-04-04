"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const [results] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'age'`
    );
    if (results.length === 0) {
      await queryInterface.addColumn("users", "age", {
        type: Sequelize.INTEGER,
        allowNull: true,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("users", "age");
  },
};
