'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('app_sessions', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: 'users', key: 'id' },
        onDelete: 'SET NULL',
      },
      platform: {
        type: Sequelize.ENUM('android', 'ios', 'web'),
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    }, { ifNotExists: true });

    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS app_sessions_created_at ON app_sessions (created_at);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS app_sessions_user_id ON app_sessions (user_id);`);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('app_sessions');
  },
};
