"use strict";

async function columnExists(queryInterface, table, column) {
  const [results] = await queryInterface.sequelize.query(
    `SELECT 1 FROM information_schema.columns WHERE table_name = '${table}' AND column_name = '${column}'`
  );
  return results.length > 0;
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, "users", "email_otp"))) {
      await queryInterface.addColumn("users", "email_otp", {
        type: Sequelize.STRING(6),
        allowNull: true,
      });
    }

    if (!(await columnExists(queryInterface, "users", "email_otp_expires"))) {
      await queryInterface.addColumn("users", "email_otp_expires", {
        type: Sequelize.DATE,
        allowNull: true,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("users", "email_otp");
    await queryInterface.removeColumn("users", "email_otp_expires");
  },
};
