"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const [r] = await queryInterface.sequelize.query(
      `SELECT 1 FROM information_schema.columns WHERE table_name = 'establishments' AND column_name = 'source'`
    );
    if (r.length === 0) {
      await queryInterface.addColumn("establishments", "source", {
        type: Sequelize.STRING(50),
        allowNull: true,
        defaultValue: "manual",
        comment: "Origine de la donnée: manual, osm, import...",
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("establishments", "source");
  },
};
