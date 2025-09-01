#!/usr/bin/env node

// Database Connection Diagnostic Tool for Render
// Run this to test your DATABASE_URL independently

require('dotenv').config();
const { sequelize } = require('./src/db');

console.log('🔍 Crown Security API - Database Diagnostic');
console.log('==========================================');

// Check environment
const env = process.env.NODE_ENV || 'development';
console.log(`📍 Environment: ${env}`);
console.log(`💾 DATABASE_URL: ${process.env.DATABASE_URL ? 'Set' : 'Not set'}`);

if (env === 'production' && !process.env.DATABASE_URL) {
  console.error('❌ DATABASE_URL not found in production environment');
  process.exit(1);
}

if (env === 'development') {
  console.log(`🏠 DB Host: ${process.env.DB_HOST || 'Not set'}`);
  console.log(`👤 DB User: ${process.env.DB_USER || 'Not set'}`);
  console.log(`📊 DB Name: ${process.env.DB_NAME || 'Not set'}`);
}

// Parse and display URL components (safely) for production
if (env === 'production' && process.env.DATABASE_URL) {
  try {
    const dbUrl = new URL(process.env.DATABASE_URL);
    console.log('\n🔍 Database URL Components:');
    console.log(`   Protocol: ${dbUrl.protocol}`);
    console.log(`   Username: ${dbUrl.username}`);
    console.log(`   Password: ${'*'.repeat(dbUrl.password.length)} (${dbUrl.password.length} chars)`);
    console.log(`   Hostname: ${dbUrl.hostname}`);
    console.log(`   Port: ${dbUrl.port || 'not specified'}`);
    console.log(`   Database: ${dbUrl.pathname.substring(1)}`);
  } catch (error) {
    console.error('❌ Invalid DATABASE_URL format:', error.message);
    process.exit(1);
  }
}

// Test connection
async function testConnection() {
  console.log('\n🔗 Testing database connection...');
  
  try {
    await sequelize.authenticate();
    console.log('✅ Database connection successful!');
    
    // Test a simple query
    const result = await sequelize.query('SELECT version() as version');
    console.log(`📊 PostgreSQL version: ${result[0][0].version.split(' ')[0]}`);
    
    // Show connection config (without sensitive data)
    const config = sequelize.config;
    console.log(`🔧 Connection config:`);
    console.log(`   Dialect: ${config.dialect}`);
    console.log(`   Host: ${config.host || 'from DATABASE_URL'}`);
    console.log(`   Database: ${config.database || 'from DATABASE_URL'}`);
    console.log(`   SSL: ${config.dialectOptions?.ssl ? 'Enabled' : 'Disabled'}`);
    
    await sequelize.close();
    console.log('✅ Connection closed successfully');
    
  } catch (error) {
    console.error('❌ Database connection failed:');
    console.error(`   Error: ${error.name}`);
    console.error(`   Code: ${error.original?.code || 'N/A'}`);
    console.error(`   Message: ${error.message}`);
    
    console.log('\n🔧 Troubleshooting suggestions:');
    if (env === 'production') {
      console.log('   1. Check if PostgreSQL service is "Available" in Render dashboard');
      console.log('   2. Verify DATABASE_URL includes port :5432');
      console.log('   3. Ensure hostname ends with .oregon-postgres.render.com');
      console.log('   4. Try getting a fresh DATABASE_URL from Render dashboard');
    } else {
      console.log('   1. Check if PostgreSQL is running locally');
      console.log('   2. Verify DB_HOST, DB_USER, DB_PASS, DB_NAME in .env');
      console.log('   3. Run: docker-compose up -d (if using Docker)');
    }
    
    process.exit(1);
  }
}

testConnection();
