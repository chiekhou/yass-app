"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    const col = async (column) => {
      const [r] = await queryInterface.sequelize.query(
        `SELECT 1 FROM information_schema.columns WHERE table_name = 'establishment_suggestions' AND column_name = '${column}'`
      );
      return r.length > 0;
    };
    if (!(await col("contact_email"))) {
      await queryInterface.addColumn("establishment_suggestions", "contact_email", {
        type: Sequelize.STRING(255),
        allowNull: true,
      });
    }
    if (!(await col("reason"))) {
      await queryInterface.addColumn("establishment_suggestions", "reason", {
        type: Sequelize.TEXT,
        allowNull: true,
      });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn("establishment_suggestions", "contact_email");
    await queryInterface.removeColumn("establishment_suggestions", "reason");
  },
};
