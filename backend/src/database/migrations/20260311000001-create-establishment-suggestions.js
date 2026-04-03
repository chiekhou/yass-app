"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    // ── Table establishment_suggestions ──────────────────────────────────────
    await queryInterface.createTable("establishment_suggestions", {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      name: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      address: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      phone: {
        type: Sequelize.STRING(50),
        allowNull: true,
      },
      description: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      category_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: "categories", key: "id" },
        onUpdate: "CASCADE",
        onDelete: "SET NULL",
      },
      wilaya_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: "wilayas", key: "id" },
        onUpdate: "CASCADE",
        onDelete: "SET NULL",
      },
      suggested_by: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: "users", key: "id" },
        onUpdate: "CASCADE",
        onDelete: "CASCADE",
      },
      vote_count: {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 1,
      },
      status: {
        type: Sequelize.ENUM("pending", "approved", "rejected"),
        allowNull: false,
        defaultValue: "pending",
      },
      admin_note: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      reviewed_by: {
        type: Sequelize.UUID,
        allowNull: true,
        references: { model: "users", key: "id" },
        onUpdate: "CASCADE",
        onDelete: "SET NULL",
      },
      reviewed_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    });

    await queryInterface.addIndex("establishment_suggestions", ["status"]);
    await queryInterface.addIndex("establishment_suggestions", ["suggested_by"]);
    await queryInterface.addIndex("establishment_suggestions", ["vote_count"]);

    // ── Table suggestion_votes ────────────────────────────────────────────────
    await queryInterface.createTable("suggestion_votes", {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      suggestion_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: "establishment_suggestions", key: "id" },
        onUpdate: "CASCADE",
        onDelete: "CASCADE",
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: "users", key: "id" },
        onUpdate: "CASCADE",
        onDelete: "CASCADE",
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW,
      },
    });

    await queryInterface.addIndex(
      "suggestion_votes",
      ["suggestion_id", "user_id"],
      { unique: true, name: "unique_suggestion_vote" }
    );
  },

  async down(queryInterface) {
    await queryInterface.dropTable("suggestion_votes");
    await queryInterface.dropTable("establishment_suggestions");
    await queryInterface.sequelize.query(
      "DROP TYPE IF EXISTS enum_establishment_suggestions_status;"
    );
  },
};
