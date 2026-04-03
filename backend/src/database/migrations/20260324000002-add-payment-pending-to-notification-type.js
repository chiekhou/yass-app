"use strict";

module.exports = {
  async up(queryInterface) {
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_notifications_type" ADD VALUE IF NOT EXISTS 'payment_pending'`
    );
  },

  async down() {
    // PostgreSQL ne permet pas de supprimer une valeur d'enum sans recrée le type
  },
};
