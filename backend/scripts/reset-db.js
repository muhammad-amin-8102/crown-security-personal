const { Sequelize } = require('sequelize');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Database configuration
const config = require('../config/config.js');
const env = process.env.NODE_ENV || 'production';
const dbConfig = config[env];

console.log('🗄️ Starting database reset for environment:', env);

async function resetDatabase() {
  let sequelize;
  
  try {
    // Initialize Sequelize
    if (dbConfig.use_env_variable) {
      sequelize = new Sequelize(process.env[dbConfig.use_env_variable], dbConfig);
    } else {
      sequelize = new Sequelize(dbConfig.database, dbConfig.username, dbConfig.password, dbConfig);
    }

    // Test connection
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');

    // Get all table names (in proper order for foreign key constraints)
    const tableOrder = [
      'Attendances',
      'Shifts', 
      'Bills',
      'Sites',
      'Users'
    ];

    console.log('🧹 Clearing all tables...');
    
    // Disable foreign key constraints temporarily
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 0', { raw: true }).catch(() => {
      // For PostgreSQL
      return sequelize.query('SET session_replication_role = replica;', { raw: true });
    });

    // Clear tables in reverse order to handle foreign keys
    for (const tableName of tableOrder.reverse()) {
      try {
        await sequelize.query(`DELETE FROM "${tableName}"`, { raw: true });
        console.log(`✅ Cleared table: ${tableName}`);
      } catch (error) {
        // Table might not exist, continue
        console.log(`⚠️ Could not clear table ${tableName}: ${error.message}`);
      }
    }

    // Reset sequences for PostgreSQL
    if (dbConfig.dialect === 'postgres') {
      const sequences = [
        'Users_id_seq',
        'Sites_id_seq', 
        'Shifts_id_seq',
        'Attendances_id_seq',
        'Bills_id_seq'
      ];
      
      for (const seq of sequences) {
        try {
          await sequelize.query(`ALTER SEQUENCE "${seq}" RESTART WITH 1`, { raw: true });
          console.log(`✅ Reset sequence: ${seq}`);
        } catch (error) {
          // Sequence might not exist, continue
          console.log(`⚠️ Could not reset sequence ${seq}: ${error.message}`);
        }
      }
    }

    // Re-enable foreign key constraints
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 1', { raw: true }).catch(() => {
      // For PostgreSQL
      return sequelize.query('SET session_replication_role = DEFAULT;', { raw: true });
    });

    console.log('🌱 Running fresh seeders...');
    
    // Run seeders using Sequelize CLI
    const { exec } = require('child_process');
    const util = require('util');
    const execPromise = util.promisify(exec);
    
    try {
      const { stdout, stderr } = await execPromise('npx sequelize-cli db:seed:all', {
        cwd: path.join(__dirname, '..')
      });
      
      if (stdout) console.log('📄 Seeder output:', stdout);
      if (stderr) console.log('⚠️ Seeder warnings:', stderr);
      
    } catch (seedError) {
      console.error('❌ Seeder error:', seedError.message);
      
      // Fallback: Run seeders manually
      console.log('🔄 Attempting manual seeding...');
      await runSeedersManually(sequelize);
    }

    console.log('🎉 Database reset completed successfully!');
    
  } catch (error) {
    console.error('❌ Database reset failed:', error);
    process.exit(1);
  } finally {
    if (sequelize) {
      await sequelize.close();
    }
  }
}

async function runSeedersManually(sequelize) {
  const bcrypt = require('bcryptjs');
  
  try {
    // Create UUID extension for PostgreSQL
    if (sequelize.getDialect() === 'postgres') {
      await sequelize.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"', { raw: true });
    }

    // Seed Users
    console.log('👥 Seeding users...');
    const passwordHash = await bcrypt.hash('Pass@123', 10);
    
    await sequelize.query(`
      INSERT INTO "Users" (id, name, email, phone, role, password_hash, active, "createdAt", "updatedAt")
      VALUES 
        (uuid_generate_v4(), 'Admin User', 'admin@crown.local', '+1234567890', 'ADMIN', :hash, true, NOW(), NOW()),
        (uuid_generate_v4(), 'Client User', 'client@crown.local', '+9999999999', 'CLIENT', :hash, true, NOW(), NOW())
    `, {
      replacements: { hash: passwordHash },
      raw: true
    });

    // Seed Sites
    console.log('🏢 Seeding sites...');
    await sequelize.query(`
      INSERT INTO "Sites" (id, name, address, contact_person, contact_phone, "createdAt", "updatedAt")
      VALUES 
        (uuid_generate_v4(), 'Downtown Office Complex', '123 Business District, City Center', 'John Manager', '+1234567890', NOW(), NOW()),
        (uuid_generate_v4(), 'Residential Tower A', '456 Residential Area, Suburb', 'Jane Supervisor', '+9876543210', NOW(), NOW()),
        (uuid_generate_v4(), 'Shopping Mall Security', '789 Commercial Street, Mall District', 'Mike Chief', '+5555555555', NOW(), NOW())
    `, { raw: true });

    console.log('✅ Manual seeding completed');
    
  } catch (error) {
    console.error('❌ Manual seeding failed:', error);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  resetDatabase();
}

module.exports = { resetDatabase };
