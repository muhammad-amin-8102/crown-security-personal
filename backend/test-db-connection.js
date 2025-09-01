#!/usr/bin/env node

// Database Connection Diagnostic Tool for Render
// Run this to test your DATABASE_URL independently

require('dotenv').config();
const { Sequelize } = require('sequelize');

console.log('🔍 Crown Security API - Database Diagnostic');
console.log('==========================================');

// Check environment
console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
console.log(`💾 DATABASE_URL: ${process.env.DATABASE_URL ? 'Set' : 'Not set'}`);

if (!process.env.DATABASE_URL) {
  console.error('❌ DATABASE_URL not found in environment variables');
  process.exit(1);
}

// Parse and display URL components (safely)
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

// Test connection
async function testConnection() {
  console.log('\n🔗 Testing database connection...');
  
  const sequelize = new Sequelize(process.env.DATABASE_URL, {
    dialect: 'postgres',
    dialectOptions: { 
      ssl: { require: true, rejectUnauthorized: false } 
    },
    logging: false
  });

  try {
    await sequelize.authenticate();
    console.log('✅ Database connection successful!');
    
    // Test a simple query
    const result = await sequelize.query('SELECT version() as version');
    console.log(`📊 PostgreSQL version: ${result[0][0].version.split(' ')[0]}`);
    
    await sequelize.close();
    console.log('✅ Connection closed successfully');
    
  } catch (error) {
    console.error('❌ Database connection failed:');
    console.error(`   Error: ${error.name}`);
    console.error(`   Code: ${error.original?.code || 'N/A'}`);
    console.error(`   Message: ${error.message}`);
    
    console.log('\n🔧 Troubleshooting suggestions:');
    console.log('   1. Check if PostgreSQL service is "Available" in Render dashboard');
    console.log('   2. Verify DATABASE_URL includes port :5432');
    console.log('   3. Ensure hostname ends with .oregon-postgres.render.com');
    console.log('   4. Try getting a fresh DATABASE_URL from Render dashboard');
    
    process.exit(1);
  }
}

testConnection();
