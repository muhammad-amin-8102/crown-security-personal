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
    
    // Auto-run migrations in production (Render)
    if (!isDevelopment) {
      console.log('🔄 Running database migrations...');
      try {
        await sequelize.sync({ alter: false });
        console.log('✅ Database migrations completed');
        
        // Run seeders in production
        console.log('🌱 Running database seeders...');
        const { exec } = require('child_process');
        const { promisify } = require('util');
        const execAsync = promisify(exec);
        
        try {
          await execAsync('npx sequelize-cli db:seed:all', { cwd: __dirname + '/..' });
          console.log('✅ Database seeders completed');
        } catch (seedError) {
          console.log('⚠️ Seeder execution failed:', seedError.message);
          // Don't fail startup if seeders fail (they might already be run)
        }
      } catch (migrationError) {
        console.log('⚠️ Migration sync failed, continuing startup:', migrationError.message);
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
