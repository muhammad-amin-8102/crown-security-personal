'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Fetch all client users
    const clients = await queryInterface.sequelize.query(
      "SELECT id, name FROM \"Users\" WHERE role = 'CLIENT';",
      { type: Sequelize.QueryTypes.SELECT }
    );

    if (!clients || clients.length === 0) return;

    const sitesToInsert = [];

    for (const c of clients) {
      // Skip if client already has at least one site
      const existing = await queryInterface.sequelize.query(
        `SELECT id FROM \"Sites\" WHERE client_id = '${c.id}' LIMIT 1;`,
        { type: Sequelize.QueryTypes.SELECT }
      );
      if (existing && existing.length > 0) continue;

      sitesToInsert.push({
        id: Sequelize.literal('uuid_generate_v4()'),
        name: `Initial Site - ${c.name}`,
        location: 'TBD',
        strength: 5,
        rate_per_guard: 0.0,
        agreement_start: new Date(),
        agreement_end: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
        area_officer_name: '',
        area_officer_phone: '',
        cro_name: '',
        cro_phone: '',
        client_id: c.id,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }

    if (sitesToInsert.length > 0) {
      await queryInterface.bulkInsert('Sites', sitesToInsert, {});
    }
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('Sites', { name: { [Sequelize.Op.like]: 'Initial Site - %' } }, {});
  }
};
