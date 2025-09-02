require('dotenv').config();
const app = require('./app');
const { sequelize } = require('./db');

const port = process.env.PORT || 3000;
const isDevelopment = process.env.NODE_ENV !== 'production';

// Database connection with retry logic
async function connectWithRetry(retries = 5, delay = 5000) {
  for (let i = 0; i < retries; i++) {
    try {
      console.log(`🔗 Attempting database connection (${i + 1}/${retries})...`);
      await sequelize.authenticate();
      console.log('✅ Database connected successfully');
      return true;
    } catch (error) {
      console.log(`❌ Database connection failed (attempt ${i + 1}/${retries}):`);
      console.log(`   Error type: ${error.name}`);
      console.log(`   Error code: ${error.original?.code || 'N/A'}`);
      console.log(`   Error message: ${error.message}`);
      
      if (i === retries - 1) {
        console.error('💥 All database connection attempts failed');
        console.error('🔍 Troubleshooting tips:');
        console.error('   1. Check if PostgreSQL service is "Available" in Render dashboard');
        console.error('   2. Verify DATABASE_URL includes port :5432');
        console.error('   3. Ensure DATABASE_URL has full hostname ending in .render.com');
        console.error('   4. PostgreSQL service may take 1-2 minutes to start after deployment');
        throw error;
      }
      
      console.log(`⏳ Waiting ${delay/1000}s before retry...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

(async () => {
  try {
    console.log('🚀 Starting Crown Security API...');
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Port: ${port}`);
    console.log(`💾 Database URL: ${process.env.DATABASE_URL ? 'Set' : 'Not set'}`);
    
    // Debug database URL format (don't log password in production)
    if (process.env.DATABASE_URL) {
      const urlParts = process.env.DATABASE_URL.replace(/:[^:@]*@/, ':***@');
      console.log(`🔍 DB URL format: ${urlParts}`);
    }
    
    // Connect to database with retry logic
    await connectWithRetry();
    
    // Auto-run migrations and seeders (both development and production)
    console.log('🔄 Running database migrations...');
    try {
      const { exec } = require('child_process');
      const { promisify } = require('util');
      const execAsync = promisify(exec);
      
      // Run migrations first
      console.log('📋 Running Sequelize migrations...');
      const migrationResult = await execAsync('npx sequelize-cli db:migrate', { 
        cwd: __dirname + '/..',
        timeout: 60000 
      });
      console.log('✅ Database migrations completed');
      console.log('📄 Migration output:', migrationResult.stdout);
      if (migrationResult.stderr) {
        console.log('⚠️ Migration warnings:', migrationResult.stderr);
      }
      
      // Wait a moment for migrations to fully commit
      await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Run seeders after migrations
        console.log('🌱 Running database seeders...');
        try {
          const seedResult = await execAsync('npx sequelize-cli db:seed:all', { 
            cwd: __dirname + '/..',
            timeout: 60000 
          });
          console.log('✅ Database seeders completed');
          console.log('📄 Seeder output:', seedResult.stdout);
          if (seedResult.stderr) {
            console.log('⚠️ Seeder warnings:', seedResult.stderr);
          }
        } catch (seedError) {
          console.log('⚠️ Seeder execution failed:', seedError.message);
          console.log('📄 Seeder stderr:', seedError.stderr || 'No stderr');
          console.log('📄 Seeder stdout:', seedError.stdout || 'No stdout');
          
          // Attempt programmatic fallback for admin user
          console.log('🔄 Attempting programmatic admin user creation...');
          try {
            const bcrypt = require('bcryptjs');
            const { User } = require('../models');
            
            const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'Admin@2025!', 10);
            const [user, created] = await User.findOrCreate({
              where: { email: process.env.ADMIN_EMAIL || 'admin@crownsecurity.com' },
              defaults: {
                name: process.env.ADMIN_NAME || 'Admin User',
                email: process.env.ADMIN_EMAIL || 'admin@crownsecurity.com',
                phone: process.env.ADMIN_PHONE || '+1234567890',
                password_hash: hashedPassword,
                role: 'ADMIN',
                active: true
              }
            });
            console.log(`✅ Admin user ${created ? 'created' : 'already exists'}`);
          } catch (userError) {
            console.log('❌ Programmatic admin user creation failed:', userError.message);
          }
          // Don't fail startup if seeders fail (they might already be run)
        }
      } catch (migrationError) {
        console.log('⚠️ Migration execution failed:', migrationError.message);
        // Try basic sync as fallback
        try {
          await sequelize.sync({ alter: false });
          console.log('✅ Database sync completed as fallback');
        } catch (syncError) {
          console.log('❌ Both migration and sync failed:', syncError.message);
        }
      }
    
    // Start server
    app.listen(port, '0.0.0.0', () => {
      console.log(`🌐 API listening on :${port}`);
      console.log(`🏥 Health check: http://localhost:${port}/api/health`);
      console.log('✅ Server started successfully');
    });
  } catch (e) {
    console.error('❌ Startup error:', e);
    process.exit(1);
  }
})();
