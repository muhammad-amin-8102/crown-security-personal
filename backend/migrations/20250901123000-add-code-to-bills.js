"use strict";
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    // Add new column 'code' to Bills table
    await queryInterface.addColumn('Bills', 'code', {
      type: Sequelize.STRING,
      allowNull: true, // temporarily allow nulls to backfill
      unique: true,
    });

    // Backfill existing rows with generated codes based on id prefix
    // Use raw SQL for efficiency; works with Postgres
    await queryInterface.sequelize.query(`
      UPDATE "Bills"
      SET code = 'BILL-' || UPPER(SUBSTRING(REPLACE(CAST(id AS TEXT), '-', '') FROM 1 FOR 8))
      WHERE code IS NULL;
    `);

    // Alter column to set NOT NULL after backfill
    await queryInterface.changeColumn('Bills', 'code', {
      type: Sequelize.STRING,
      allowNull: false,
      unique: true,
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('Bills', 'code');
  }
};
