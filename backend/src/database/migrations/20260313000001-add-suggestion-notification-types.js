'use strict';

/** Ajoute les valeurs suggestion_approved et suggestion_rejected à l'ENUM notifications.type */
module.exports = {
  async up(queryInterface) {
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_notifications_type" ADD VALUE IF NOT EXISTS 'suggestion_approved';`
    );
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_notifications_type" ADD VALUE IF NOT EXISTS 'suggestion_rejected';`
    );
  },

  async down() {
    // PostgreSQL ne supporte pas la suppression de valeurs d'un ENUM sans le recréer
  },
};
