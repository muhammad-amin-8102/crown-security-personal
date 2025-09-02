'use strict';
const bcrypt = require('bcryptjs');

module.exports = {
  async up (queryInterface, Sequelize) {
    const email = process.env.ADMIN_EMAIL || 'admin@crownsecurity.com';
    const name = process.env.ADMIN_NAME || 'Admin User';
    const phone = process.env.ADMIN_PHONE || '+1234567890';
    const password = process.env.ADMIN_PASSWORD || 'Admin@2025!';
    const hash = await bcrypt.hash(password, 10);

    const [rows] = await queryInterface.sequelize.query(
      'SELECT id FROM "Users" WHERE email = :email LIMIT 1',
      { replacements: { email } }
    );

    if (!rows || rows.length === 0) {
      await queryInterface.bulkInsert('Users', [{
        id: Sequelize.literal('uuid_generate_v4()'),
        name,
        email,
        phone,
        role: 'ADMIN',
        password_hash: hash,
        active: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      }], {});
    } else {
      // Ensure the found user is active and has ADMIN role
      await queryInterface.bulkUpdate('Users', { role: 'ADMIN', active: true }, { email });
    }
  },

  async down (queryInterface) {
    const email = process.env.ADMIN_EMAIL || 'admin@crownsecurity.com';
    await queryInterface.bulkDelete('Users', { email });
  }
};
