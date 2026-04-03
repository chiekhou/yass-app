'use strict';

/** Ajoute la valeur suggestion_pending à l'ENUM notifications.type */
module.exports = {
  async up(queryInterface) {
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_notifications_type" ADD VALUE IF NOT EXISTS 'suggestion_pending';`
    );
  },

  async down() {
    // PostgreSQL ne permet pas de supprimer une valeur d'un ENUM
  },
};
