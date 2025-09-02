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
    
    // For PostgreSQL, use TRUNCATE CASCADE which is more reliable
    if (dbConfig.dialect === 'postgres') {
      // Disable foreign key constraints temporarily
      await sequelize.query('SET session_replication_role = replica;', { raw: true });

      // Use TRUNCATE CASCADE for clean deletion
      for (const tableName of tableOrder.reverse()) {
        try {
          await sequelize.query(`TRUNCATE TABLE "${tableName}" RESTART IDENTITY CASCADE`, { raw: true });
          console.log(`✅ Truncated table: ${tableName}`);
        } catch (error) {
          console.log(`⚠️ Could not truncate table ${tableName}: ${error.message}`);
          // Fallback to DELETE
          try {
            await sequelize.query(`DELETE FROM "${tableName}"`, { raw: true });
            console.log(`✅ Deleted from table: ${tableName}`);
          } catch (deleteError) {
            console.log(`❌ Could not clear table ${tableName}: ${deleteError.message}`);
          }
        }
      }

      // Re-enable foreign key constraints
      await sequelize.query('SET session_replication_role = DEFAULT;', { raw: true });
    } else {
      // For other databases (MySQL, etc.)
      await sequelize.query('SET FOREIGN_KEY_CHECKS = 0', { raw: true });

      for (const tableName of tableOrder.reverse()) {
        try {
          await sequelize.query(`DELETE FROM "${tableName}"`, { raw: true });
          console.log(`✅ Cleared table: ${tableName}`);
        } catch (error) {
          console.log(`⚠️ Could not clear table ${tableName}: ${error.message}`);
        }
      }

      await sequelize.query('SET FOREIGN_KEY_CHECKS = 1', { raw: true });
    }

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
    
    const userResults = await sequelize.query(`
      INSERT INTO "Users" (id, name, email, phone, role, password_hash, active, "createdAt", "updatedAt")
      VALUES 
        (uuid_generate_v4(), 'Admin User', 'admin@crown.local', '+1234567890', 'ADMIN', :hash, true, NOW(), NOW()),
        (uuid_generate_v4(), 'Client User', 'client@crown.local', '+9999999999', 'CLIENT', :hash, true, NOW(), NOW())
      RETURNING id, email
    `, {
      replacements: { hash: passwordHash },
      type: sequelize.QueryTypes.INSERT
    });

    console.log('✅ Users seeded');

    // Get client user ID for site assignment
    const [clientUser] = await sequelize.query(`
      SELECT id FROM "Users" WHERE email = 'client@crown.local' LIMIT 1
    `, {
      type: sequelize.QueryTypes.SELECT
    });

    // Seed Sites with client assignment
    console.log('🏢 Seeding sites...');
    await sequelize.query(`
      INSERT INTO "Sites" (id, name, address, contact_person, contact_phone, client_id, "createdAt", "updatedAt")
      VALUES 
        (uuid_generate_v4(), 'Downtown Office Complex', '123 Business District, City Center', 'John Manager', '+1234567890', :clientId, NOW(), NOW()),
        (uuid_generate_v4(), 'Residential Tower A', '456 Residential Area, Suburb', 'Jane Supervisor', '+9876543210', :clientId, NOW(), NOW()),
        (uuid_generate_v4(), 'Shopping Mall Security', '789 Commercial Street, Mall District', 'Mike Chief', '+5555555555', :clientId, NOW(), NOW())
    `, { 
      replacements: { clientId: clientUser.id },
      raw: true 
    });

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
