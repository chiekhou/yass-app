'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Add fcm_token to users if not already present
    try {
      await queryInterface.addColumn('users', 'fcm_token', {
        type: Sequelize.STRING(500),
        allowNull: true,
      });
    } catch (err) {
      // Column may already exist — skip
      console.log('[migration] fcm_token already exists on users, skipping.');
    }

    // Create notifications table
    await queryInterface.createTable('notifications', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: 'users', key: 'id' },
        onDelete: 'CASCADE',
      },
      type: {
        type: Sequelize.ENUM(
          'partner_approved',
          'partner_rejected',
          'establishment_approved',
          'establishment_rejected',
          'payment_validated',
          'subscription_expiring',
          'review_new',
          'review_reply'
        ),
        allowNull: false,
      },
      title: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      body: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      data: {
        type: Sequelize.JSONB,
        allowNull: true,
      },
      is_read: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
        allowNull: false,
      },
      read_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.fn('NOW'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.fn('NOW'),
      },
    }, { ifNotExists: true });

    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS notifications_user_id ON notifications (user_id);`);
    await queryInterface.sequelize.query(`CREATE INDEX IF NOT EXISTS notifications_user_id_is_read ON notifications (user_id, is_read);`);
  },

  down: async (queryInterface) => {
    await queryInterface.dropTable('notifications');
    try {
      await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_notifications_type";');
    } catch (err) {
      // ignore
    }
    try {
      await queryInterface.removeColumn('users', 'fcm_token');
    } catch (err) {
      // ignore
    }
  },
};
