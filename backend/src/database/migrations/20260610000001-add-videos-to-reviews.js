'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('reviews', 'videos', {
      type: Sequelize.JSONB,
      allowNull: true,
      defaultValue: [],
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('reviews', 'videos');
  },
};
