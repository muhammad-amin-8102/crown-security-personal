"use strict";

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Create uuid-ossp extension so uuid_generate_v4() is available to seeds/migrations
    await queryInterface.sequelize.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";');
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.sequelize.query('DROP EXTENSION IF EXISTS "uuid-ossp";');
  }
};
