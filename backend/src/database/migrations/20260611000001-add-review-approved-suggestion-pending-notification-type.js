'use strict';

module.exports = {
  up: async (queryInterface) => {
    // PostgreSQL requires ALTER TYPE to add new ENUM values
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_notifications_type" ADD VALUE IF NOT EXISTS 'review_approved';`
    );
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_notifications_type" ADD VALUE IF NOT EXISTS 'suggestion_pending';`
    );
  },

  down: async () => {
    // PostgreSQL doesn't support removing ENUM values without recreating the type.
    // This migration is intentionally non-reversible to avoid data loss.
  },
};
