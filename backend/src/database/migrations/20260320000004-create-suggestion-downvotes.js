"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable("suggestion_downvotes", {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      suggestion_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: "establishment_suggestions", key: "id" },
        onDelete: "CASCADE",
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: { model: "users", key: "id" },
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
    }, { ifNotExists: true });

    await queryInterface.sequelize.query(`CREATE UNIQUE INDEX IF NOT EXISTS unique_suggestion_downvote ON suggestion_downvotes (suggestion_id, user_id);`);
  },

  async down(queryInterface) {
    await queryInterface.dropTable("suggestion_downvotes");
  },
};
