'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const [results] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_elite'`
    );
    if (results.length === 0) {
      await queryInterface.addColumn('users', 'is_elite', {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('users', 'is_elite');
  },
};
