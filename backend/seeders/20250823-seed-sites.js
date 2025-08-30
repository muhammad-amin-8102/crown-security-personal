'use strict';


module.exports = {
  async up (queryInterface, Sequelize) {
    // Get client user id
    const [client] = await queryInterface.sequelize.query(
      "SELECT id FROM \"Users\" WHERE email = 'client@crown.local' LIMIT 1;",
      { type: Sequelize.QueryTypes.SELECT }
    );
    const clientId = client?.id || null;
    await queryInterface.bulkInsert('Sites', [{
      id: Sequelize.literal('uuid_generate_v4()'),
      name: 'Test Site 1',
      location: '123 Test Ave',
      strength: 10,
      rate_per_guard: 15.00,
      agreement_start: new Date('2023-01-01'),
      agreement_end: new Date('2026-01-01'),
      area_officer_name: 'John Doe',
      area_officer_phone: '555-123-4567',
      cro_name: 'Jane Smith',
      cro_phone: '555-987-6543',
      client_id: clientId,
      createdAt: new Date(), updatedAt: new Date()
    },{
      id: Sequelize.literal('uuid_generate_v4()'),
      name: 'Test Site 2',
      location: '456 Main St',
      strength: 5,
      rate_per_guard: 20.00,
      agreement_start: new Date('2024-06-01'),
      agreement_end: new Date('2025-06-01'),
      area_officer_name: 'John Doe',
      area_officer_phone: '555-123-4567',
      cro_name: 'Jane Smith',
      cro_phone: '555-987-6543',
      client_id: clientId,
      createdAt: new Date(), updatedAt: new Date()
    }], {});
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.bulkDelete('Sites', null, {});
  }
};
