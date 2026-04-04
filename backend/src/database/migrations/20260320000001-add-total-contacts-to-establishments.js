'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    const [results] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'establishments' AND column_name = 'total_contacts'`
    );
    if (results.length === 0) {
      await queryInterface.addColumn('establishments', 'total_contacts', {
        type: Sequelize.INTEGER,
        defaultValue: 0,
        allowNull: false,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('establishments', 'total_contacts');
  },
};
