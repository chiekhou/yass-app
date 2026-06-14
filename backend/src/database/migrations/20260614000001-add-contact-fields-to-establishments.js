'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    const tableDesc = await queryInterface.describeTable('establishments');

    if (!tableDesc.contact_first_name) {
      await queryInterface.addColumn('establishments', 'contact_first_name', {
        type: Sequelize.STRING(100),
        allowNull: true,
        after: 'website',
      });
    }
    if (!tableDesc.contact_last_name) {
      await queryInterface.addColumn('establishments', 'contact_last_name', {
        type: Sequelize.STRING(100),
        allowNull: true,
      });
    }
    if (!tableDesc.contact_phone) {
      await queryInterface.addColumn('establishments', 'contact_phone', {
        type: Sequelize.STRING(20),
        allowNull: true,
      });
    }
    if (!tableDesc.contact_email) {
      await queryInterface.addColumn('establishments', 'contact_email', {
        type: Sequelize.STRING(255),
        allowNull: true,
      });
    }
    if (!tableDesc.contact_position) {
      await queryInterface.addColumn('establishments', 'contact_position', {
        type: Sequelize.STRING(150),
        allowNull: true,
      });
    }
  },

  down: async (queryInterface) => {
    const tableDesc = await queryInterface.describeTable('establishments');
    for (const col of ['contact_first_name', 'contact_last_name', 'contact_phone', 'contact_email', 'contact_position']) {
      if (tableDesc[col]) {
        await queryInterface.removeColumn('establishments', col);
      }
    }
  },
};
