const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');

const routes = require('./routes');

const app = express();

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https://www.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://www.gstatic.com", "https://fonts.gstatic.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com", "data:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
      workerSrc: ["'self'", "blob:"],
      childSrc: ["'self'", "blob:"],
    },
  },
}));

// CORS configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production' 
    ? process.env.FRONTEND_URL || ['https://*.onrender.com', 'https://*.vercel.app', 'https://*.netlify.app']
    : true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '1mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'tiny'));

// Serve Flutter web app
app.use('/admin', express.static(path.join(__dirname, '../public/admin')));

// Health check endpoint
app.get('/health', (_req, res) => res.json({ 
  ok: true, 
  name: 'Crown Security API', 
  version: process.env.APP_VERSION || '1.0.0',
  environment: process.env.NODE_ENV || 'development',
  timestamp: new Date().toISOString()
}));

// Debug endpoint to check database tables
app.get('/debug', async (req, res) => {
  try {
    console.log('🔍 Debug endpoint called - checking database state...');
    
    // Get all tables
    const [tables] = await sequelize.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);
    
    console.log('📋 Available tables:', tables);
    
    // Check Users table specifically
    let usersInfo = 'Table not found';
    try {
      const [usersResult] = await sequelize.query(`
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'Users' AND table_schema = 'public'
        ORDER BY ordinal_position;
      `);
      usersInfo = usersResult;
    } catch (usersError) {
      usersInfo = `Error checking Users table: ${usersError.message}`;
    }
    
    // Check if migrations were run
    let migrationsInfo = 'SequelizeMeta table not found';
    try {
      const [migrationResult] = await sequelize.query(`
        SELECT name FROM "SequelizeMeta" ORDER BY name;
      `);
      migrationsInfo = migrationResult;
    } catch (migError) {
      migrationsInfo = `Error checking migrations: ${migError.message}`;
    }
    
    res.json({
      database_url: process.env.DATABASE_URL ? 'Set' : 'Not set',
      tables: tables.map(t => t.table_name),
      users_table_info: usersInfo,
      migrations_run: migrationsInfo,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Debug endpoint error:', error);
    res.status(500).json({
      error: 'Debug failed',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Manual seeding endpoint for production
app.post('/seed', async (req, res) => {
  try {
    if (process.env.NODE_ENV !== 'production') {
      return res.status(403).json({ error: 'Seeding only available in production' });
    }
    
    console.log('🔄 Manual migration and seeding triggered...');
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);
    
    // Run migrations first
    console.log('📋 Running migrations...');
    const migrationResult = await execAsync('npx sequelize-cli db:migrate', { 
      cwd: __dirname + '/..',
      timeout: 60000 
    });
    
    // Then run seeders
    console.log('🌱 Running seeders...');
    const seedResult = await execAsync('npx sequelize-cli db:seed:all', { 
      cwd: __dirname + '/..',
      timeout: 60000 
    });
    
    console.log('✅ Manual migration and seeding completed');
    res.json({
      success: true,
      message: 'Database migration and seeding completed',
      migration_output: migrationResult.stdout,
      seed_output: seedResult.stdout,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Manual migration/seeding failed:', error.message);
    res.status(500).json({
      success: false,
      error: 'Migration/Seeding failed',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Legacy health check
app.get('/api/health', (_req, res) => res.json({ ok: true, name: 'Crown Security', ts: Date.now() }));

// API routes
app.use('/api/v1', routes);

// Serve Flutter web app for admin routes
app.get('/admin/*', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin/index.html'));
});

// Root redirect to admin
app.get('/', (req, res) => {
  res.redirect('/admin');
});

// 404 handler for API routes
app.use('/api/*', (req, res) => {
  res.status(404).json({ 
    error: 'API route not found',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

// Catch-all handler for other routes
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString(),
    suggestion: 'Try /admin for the admin portal or /api/v1 for API endpoints'
  });
});

module.exports = app;
