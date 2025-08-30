"use strict";

module.exports = {
  async up(queryInterface, Sequelize) {
    // Find a site to attach data to
    const [siteRow] = await queryInterface.sequelize.query(
      'SELECT id, client_id FROM "Sites" ORDER BY "createdAt" ASC LIMIT 1;',
      { type: Sequelize.QueryTypes.SELECT }
    );
    if (!siteRow) return;
    const siteId = siteRow.id;
    const clientId = siteRow.client_id;

    // 1) Shifts (a couple of recent entries)
  await queryInterface.bulkInsert('Shifts', [
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        date: new Date(),
        shift_type: 'DAY',
    guard_count: 8,
        createdAt: new Date(), updatedAt: new Date(),
      },
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        date: new Date(Date.now() - 86400000),
        shift_type: 'NIGHT',
    guard_count: 7,
        createdAt: new Date(), updatedAt: new Date(),
      },
    ]);

    // 2) Attendance (last 5 days, PRESENT for most)
  const attendanceRows = [];
    for (let i = 0; i < 5; i++) {
      const d = new Date(Date.now() - i * 86400000);
      attendanceRows.push({
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
    guard_id: Sequelize.literal('uuid_generate_v4()'),
        date: d,
        status: i === 2 ? 'ABSENT' : 'PRESENT',
        createdAt: new Date(), updatedAt: new Date(),
      });
    }
  await queryInterface.bulkInsert('Attendances', attendanceRows);

    // 3) Night Round (one latest)
    await queryInterface.bulkInsert('NightRounds', [{
      id: Sequelize.literal('uuid_generate_v4()'),
      site_id: siteId,
      date: new Date(),
      officer_id: Sequelize.literal('uuid_generate_v4()'),
      findings: 'All posts checked. Minor lighting issue near Gate 2.',
      createdAt: new Date(), updatedAt: new Date(),
    }]);

    // 4) Training Report (latest)
    await queryInterface.bulkInsert('TrainingReports', [{
      id: Sequelize.literal('uuid_generate_v4()'),
      site_id: siteId,
      date: new Date(),
      attendance_count: 9,
      topics: 'Discipline, Safety, Fire drill',
      createdAt: new Date(), updatedAt: new Date(),
    }]);

    // 5) Salary Disbursement (one month)
    await queryInterface.bulkInsert('SalaryDisbursements', [{
      id: Sequelize.literal('uuid_generate_v4()'),
      site_id: siteId,
      month: new Date(`${new Date().getFullYear()}-${String(new Date().getMonth()+1).padStart(2,'0')}-01`),
      status: 'PAID',
      date_paid: new Date(),
      createdAt: new Date(), updatedAt: new Date(),
    }]);

    // 6) Complaints (a couple)
    await queryInterface.bulkInsert('Complaints', [
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        client_id: clientId,
        complaint_text: 'Delay in guard shift change observed last night.',
        status: 'OPEN',
        createdAt: new Date(), updatedAt: new Date(),
      },
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        client_id: clientId,
        complaint_text: 'Request additional patrolling near warehouse.',
        status: 'RESOLVED',
        createdAt: new Date(), updatedAt: new Date(),
      },
    ]);

    // 7) Ratings (current month)
    await queryInterface.bulkInsert('Ratings', [{
      id: Sequelize.literal('uuid_generate_v4()'),
      site_id: siteId,
      client_id: clientId,
      month: new Date(`${new Date().getFullYear()}-${String(new Date().getMonth()+1).padStart(2,'0')}-01`),
      rating_value: 4,
      nps_score: 8,
      createdAt: new Date(), updatedAt: new Date(),
    }]);

    // 8) Bills (SOA)
  await queryInterface.bulkInsert('Bills', [
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        amount: 45000,
        due_date: new Date(Date.now() + 86400000 * 10),
        status: 'OUTSTANDING',
        createdAt: new Date(), updatedAt: new Date(),
      },
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        amount: 43000,
        due_date: new Date(Date.now() - 86400000 * 20),
        status: 'PAID',
        createdAt: new Date(), updatedAt: new Date(),
      }
    ]);

    // 9) Spend (couple of entries)
    await queryInterface.bulkInsert('Spends', [
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        date: new Date(Date.now() - 86400000 * 2),
        amount: 1250.50,
        description: 'Batteries for torches',
        createdAt: new Date(), updatedAt: new Date(),
      },
      {
        id: Sequelize.literal('uuid_generate_v4()'),
        site_id: siteId,
        date: new Date(Date.now() - 86400000 * 5),
        amount: 780.00,
        description: 'First-aid kit refills',
        createdAt: new Date(), updatedAt: new Date(),
      }
    ]);
  },

  async down(queryInterface, Sequelize) {
    // Best-effort cleanup for the first site inserted rows
    const [siteRow] = await queryInterface.sequelize.query(
      'SELECT id FROM "Sites" ORDER BY "createdAt" ASC LIMIT 1;',
      { type: Sequelize.QueryTypes.SELECT }
    );
    if (!siteRow) return;
    const siteId = siteRow.id;
    await queryInterface.bulkDelete('Shifts', { site_id: siteId });
    await queryInterface.bulkDelete('Attendance', { site_id: siteId });
    await queryInterface.bulkDelete('NightRounds', { site_id: siteId });
    await queryInterface.bulkDelete('TrainingReports', { site_id: siteId });
    await queryInterface.bulkDelete('SalaryDisbursements', { site_id: siteId });
    await queryInterface.bulkDelete('Complaints', { site_id: siteId });
    await queryInterface.bulkDelete('Ratings', { site_id: siteId });
    await queryInterface.bulkDelete('Bills', { site_id: siteId });
    await queryInterface.bulkDelete('Spends', { site_id: siteId });
  }
};
