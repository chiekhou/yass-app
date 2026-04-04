"use strict";

async function columnExists(queryInterface, table, column) {
  const [results] = await queryInterface.sequelize.query(
    `SELECT 1 FROM information_schema.columns WHERE table_name = '${table}' AND column_name = '${column}'`
  );
  return results.length > 0;
}

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.changeColumn("users", "email", {
      type: Sequelize.STRING(255),
      allowNull: true,
      unique: true,
    });

    if (!(await columnExists(queryInterface, "users", "phone_otp"))) {
      await queryInterface.addColumn("users", "phone_otp", {
        type: Sequelize.STRING(6),
        allowNull: true,
      });
    }

    if (!(await columnExists(queryInterface, "users", "phone_otp_expires"))) {
      await queryInterface.addColumn("users", "phone_otp_expires", {
        type: Sequelize.DATE,
        allowNull: true,
      });
    }
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn("users", "phone_otp");
    await queryInterface.removeColumn("users", "phone_otp_expires");

    await queryInterface.changeColumn("users", "email", {
      type: Sequelize.STRING(255),
      allowNull: false,
      unique: true,
    });
  },
};
