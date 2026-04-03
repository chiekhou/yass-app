"use strict";
const { v4: uuidv4 } = require("uuid");
const bcrypt = require("bcryptjs");

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const now = new Date();
    const hashedPassword = await bcrypt.hash("Partner@123", 12);

    // Get admin user ID for verified_by
    const [admin] = await queryInterface.sequelize.query(
      `SELECT id FROM users WHERE role = 'super_admin' LIMIT 1;`,
      { type: Sequelize.QueryTypes.SELECT },
    );
    const adminId = admin ? admin.id : null;

    // Get wilaya IDs
    const wilayas = await queryInterface.sequelize.query(
      `SELECT id, code FROM wilayas WHERE code IN ('16', '31', '25', '23', '15');`,
      { type: Sequelize.QueryTypes.SELECT },
    );
    const wilayaMap = {};
    wilayas.forEach((w) => {
      wilayaMap[w.code] = w.id;
    });

    // Partner users data
    const partnerUsers = [
      {
        id: uuidv4(),
        email: "restaurant.eldjazair@test.com",
        first_name: "Karim",
        last_name: "Benali",
        phone: "0551234567",
        wilaya_id: wilayaMap["16"],
        company_name: "Restaurant El Djazair",
        registration_number: "RC16/00-12345",
        tax_id: "NIF001234567890",
      },
      {
        id: uuidv4(),
        email: "salon.nour@test.com",
        first_name: "Fatima",
        last_name: "Zohra",
        phone: "0552345678",
        wilaya_id: wilayaMap["16"],
        company_name: "Salon de Coiffure Nour",
        registration_number: "RC16/00-23456",
      },
      {
        id: uuidv4(),
        email: "garage.amine@test.com",
        first_name: "Amine",
        last_name: "Hadj",
        phone: "0553456789",
        wilaya_id: wilayaMap["31"],
        company_name: "Garage Auto Amine",
        registration_number: "RC31/00-34567",
        tax_id: "NIF002345678901",
      },
      {
        id: uuidv4(),
        email: "hotel.cirta@test.com",
        first_name: "Youcef",
        last_name: "Mansouri",
        phone: "0554567890",
        wilaya_id: wilayaMap["25"],
        company_name: "Hôtel Cirta Palace",
        registration_number: "RC25/00-45678",
        tax_id: "NIF003456789012",
      },
      {
        id: uuidv4(),
        email: "pharmacie.centrale@test.com",
        first_name: "Samira",
        last_name: "Belkacem",
        phone: "0555678901",
        wilaya_id: wilayaMap["23"],
        company_name: "Pharmacie Centrale",
        registration_number: "RC23/00-56789",
        tax_id: "NIF004567890123",
      },
      {
        id: uuidv4(),
        email: "cafe.tizi@test.com",
        first_name: "Massinissa",
        last_name: "Ait Ahmed",
        phone: "0556789012",
        wilaya_id: wilayaMap["15"],
        company_name: "Café Djurdjura",
        registration_number: "RC15/00-67890",
      },
      {
        id: uuidv4(),
        email: "location.cars@test.com",
        first_name: "Rachid",
        last_name: "Boumediene",
        phone: "0557890123",
        wilaya_id: wilayaMap["16"],
        company_name: "Location Auto Plus",
        registration_number: "RC16/00-78901",
        tax_id: "NIF005678901234",
      },
      {
        id: uuidv4(),
        email: "pizza.napoli@test.com",
        first_name: "Mohamed",
        last_name: "Cherif",
        phone: "0558901234",
        wilaya_id: wilayaMap["31"],
        company_name: "Pizza Napoli",
        registration_number: "RC31/00-89012",
      },
      {
        id: uuidv4(),
        email: "spa.relaxation@test.com",
        first_name: "Amina",
        last_name: "Kaddour",
        phone: "0559012345",
        wilaya_id: wilayaMap["16"],
        company_name: "Spa & Hammam Relaxation",
        registration_number: "RC16/00-90123",
      },
      {
        id: uuidv4(),
        email: "salle.fetes@test.com",
        first_name: "Nadia",
        last_name: "Hamidi",
        phone: "0560123456",
        wilaya_id: wilayaMap["25"],
        company_name: "Salle des Fêtes El Amir",
        registration_number: "RC25/00-01234",
        tax_id: "NIF006789012345",
      },
    ];

    // Create users
    const usersToInsert = partnerUsers.map((p) => ({
      id: p.id,
      email: p.email,
      password: hashedPassword,
      first_name: p.first_name,
      last_name: p.last_name,
      phone: p.phone,
      role: "partner",
      status: "active",
      language: "fr",
      email_verified: true,
      wilaya_id: p.wilaya_id,
      created_at: now,
      updated_at: now,
    }));

    // Récupérer les IDs des utilisateurs test existants
    const existingTestUsers = await queryInterface.sequelize.query(
      `SELECT id FROM users WHERE email LIKE '%@test.com';`,
      { type: Sequelize.QueryTypes.SELECT }
    );
    const existingUserIds = existingTestUsers.map((u) => u.id);

    if (existingUserIds.length > 0) {
      // Supprimer dans l'ordre des dépendances (foreign keys)
      // 1. Supprimer les établissements liés aux partenaires de ces utilisateurs
      await queryInterface.sequelize.query(
        `DELETE FROM establishments WHERE partner_id IN (SELECT id FROM partners WHERE user_id IN (:userIds));`,
        { replacements: { userIds: existingUserIds } }
      );
      // 2. Supprimer les refresh_tokens liés aux utilisateurs
      await queryInterface.sequelize.query(
        `DELETE FROM refresh_tokens WHERE user_id IN (:userIds);`,
        { replacements: { userIds: existingUserIds } }
      );
      // 3. Supprimer les favoris liés aux utilisateurs
      await queryInterface.sequelize.query(
        `DELETE FROM favorites WHERE user_id IN (:userIds);`,
        { replacements: { userIds: existingUserIds } }
      );
      // 4. Supprimer les reviews liés aux utilisateurs
      await queryInterface.sequelize.query(
        `DELETE FROM reviews WHERE user_id IN (:userIds);`,
        { replacements: { userIds: existingUserIds } }
      );
      // 5. Supprimer les partenaires liés aux utilisateurs
      await queryInterface.sequelize.query(
        `DELETE FROM partners WHERE user_id IN (:userIds);`,
        { replacements: { userIds: existingUserIds } }
      );
      // 6. Supprimer les utilisateurs test
      await queryInterface.bulkDelete("users", {
        email: { [Sequelize.Op.like]: "%@test.com" },
      });
    }

    await queryInterface.bulkInsert("users", usersToInsert, {});

    // Create partners
    const partnersToInsert = partnerUsers.map((p) => ({
      id: uuidv4(),
      user_id: p.id,
      company_name: p.company_name,
      registration_number: p.registration_number || null,
      tax_id: p.tax_id || null,
      status: "approved",
      subscription_plan: "free",
      verified_at: now,
      verified_by: adminId,
      created_at: now,
      updated_at: now,
    }));

    // Supprimer les anciens partenaires test avant d'insérer
    await queryInterface.bulkDelete("partners", null, {});
    await queryInterface.bulkInsert("partners", partnersToInsert, {});
  },

  async down(queryInterface, Sequelize) {
    // Delete partners first (foreign key constraint)
    await queryInterface.bulkDelete("partners", null, {});
    // Delete partner users
    await queryInterface.bulkDelete(
      "users",
      {
        email: {
          [Sequelize.Op.like]: "%@test.com",
        },
      },
      {},
    );
  },
};
