require('dotenv').config();
const app = require('./app');
const { sequelize } = require('./db');

const port = process.env.PORT || 3000;
const isDevelopment = process.env.NODE_ENV !== 'production';

(async () => {
  try {
    console.log('🚀 Starting Crown Security API...');
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Port: ${port}`);
    
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connected successfully');
    
    // Auto-run migrations in production (Railway)
    if (!isDevelopment) {
      console.log('🔄 Running database migrations...');
      await sequelize.sync({ alter: false });
      console.log('✅ Database migrations completed');
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
