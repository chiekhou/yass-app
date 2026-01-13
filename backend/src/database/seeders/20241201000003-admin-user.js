"use strict";
const { v4: uuidv4 } = require("uuid");
const bcrypt = require("bcryptjs");

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const now = new Date();
    const hashedPassword = await bcrypt.hash("Admin@123456", 12);

    await queryInterface.bulkInsert(
      "users",
      [
        {
          id: uuidv4(),
          email: "admin@annuaire-dz.com",
          password: hashedPassword,
          first_name: "Admin",
          last_name: "System",
          role: "super_admin",
          status: "active",
          language: "fr",
          email_verified: true,
          created_at: now,
          updated_at: now,
        },
      ],
      {}
    );
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete(
      "users",
      { email: "admin@annuaire-dz.com" },
      {}
    );
  },
};
