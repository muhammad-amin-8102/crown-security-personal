'use strict';
/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('Sites', {
      id: {
        allowNull: false,
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4
      },
      name: {
        type: Sequelize.STRING
      },
      location: {
        type: Sequelize.STRING
      },
      strength: {
        type: Sequelize.INTEGER
      },
      rate_per_guard: {
        type: Sequelize.DECIMAL
      },
      agreement_start: {
        type: Sequelize.DATE
      },
      agreement_end: {
        type: Sequelize.DATE
      },
      area_officer_name: {
        type: Sequelize.STRING
      },
      area_officer_phone: {
        type: Sequelize.STRING
      },
      cro_name: {
        type: Sequelize.STRING
      },
      cro_phone: {
        type: Sequelize.STRING
      },
      client_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'Users',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  async down(queryInterface, Sequelize) {
    await queryInterface.dropTable('Sites');
  }
};
