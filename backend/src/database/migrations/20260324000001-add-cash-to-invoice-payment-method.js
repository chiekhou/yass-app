"use strict";

module.exports = {
  async up(queryInterface) {
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_invoices_payment_method" ADD VALUE IF NOT EXISTS 'cash'`
    );
  },

  async down() {
    // PostgreSQL ne permet pas de supprimer une valeur d'enum sans recrée le type
  },
};
