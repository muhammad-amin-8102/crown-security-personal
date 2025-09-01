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

// Debug endpoint for production troubleshooting
app.get('/debug', (_req, res) => {
  const envVars = {
    NODE_ENV: process.env.NODE_ENV,
    PORT: process.env.PORT,
    DATABASE_URL: process.env.DATABASE_URL ? 'Set' : 'Not set',
    JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET ? 'Set' : 'Not set',
    JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET ? 'Set' : 'Not set',
  };
  
  res.json({
    server: 'Crown Security API',
    status: 'running',
    environment: envVars,
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
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
