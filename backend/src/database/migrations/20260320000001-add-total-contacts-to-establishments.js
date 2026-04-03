'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('establishments', 'total_contacts', {
      type: Sequelize.INTEGER,
      defaultValue: 0,
      allowNull: false,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('establishments', 'total_contacts');
  },
};
