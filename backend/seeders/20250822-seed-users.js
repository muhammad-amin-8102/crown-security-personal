'use strict';
const bcrypt = require('bcryptjs');

module.exports = {
  async up (queryInterface, Sequelize) {
    const hash = await bcrypt.hash('Pass@123', 10);
    await queryInterface.bulkInsert('Users', [{
      id: Sequelize.literal('uuid_generate_v4()'),
      name: 'Client User',
      email: 'client@crown.local',
      phone: '9999999999',
      role: 'CLIENT',
      password_hash: hash,
      active: true,
      createdAt: new Date(), updatedAt: new Date()
    },{
      id: Sequelize.literal('uuid_generate_v4()'),
      name: 'Admin',
      email: 'admin@crown.local',
      phone: '8888888888',
      role: 'ADMIN',
      password_hash: hash,
      active: true,
      createdAt: new Date(), updatedAt: new Date()
    }], {});
  },
  async down (queryInterface) {
    await queryInterface.bulkDelete('Users', null, {});
  }
};
