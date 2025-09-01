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
      console.log(`❌ Database connection failed (attempt ${i + 1}/${retries}):`, error.message);
      
      if (i === retries - 1) {
        console.error('💥 All database connection attempts failed');
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
    
    // Connect to database with retry logic
    await connectWithRetry();
    
    // Auto-run migrations in production (Render)
    if (!isDevelopment) {
      console.log('🔄 Running database migrations...');
      try {
        await sequelize.sync({ alter: false });
        console.log('✅ Database migrations completed');
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
