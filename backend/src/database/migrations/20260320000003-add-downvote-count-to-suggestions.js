"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const [r] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'establishment_suggestions' AND column_name = 'downvote_count'`
    );
    if (r.length === 0) {
      await queryInterface.addColumn("establishment_suggestions", "downvote_count", {
        type: Sequelize.INTEGER,
        allowNull: false,
        defaultValue: 0,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("establishment_suggestions", "downvote_count");
  },
};
