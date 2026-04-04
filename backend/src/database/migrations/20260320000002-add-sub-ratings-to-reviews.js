'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const [results] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'sub_ratings'`
    );
    if (results.length === 0) {
      await queryInterface.addColumn('reviews', 'sub_ratings', {
        type: Sequelize.JSONB,
        allowNull: true,
        defaultValue: null,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('reviews', 'sub_ratings');
  },
};
