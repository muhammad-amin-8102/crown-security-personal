const { Sequelize } = require('sequelize');
const config = require('../config/config.js');

const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

let sequelize;

if (dbConfig.use_env_variable) {
  // Production environment - use DATABASE_URL
  sequelize = new Sequelize(process.env[dbConfig.use_env_variable], {
    dialect: dbConfig.dialect,
    dialectOptions: dbConfig.dialectOptions,
    define: { underscored: true, freezeTableName: true },
    logging: dbConfig.logging || false,
    pool: dbConfig.pool || {
      max: 5,
      min: 0,
      acquire: 60000,
      idle: 10000
    }
  });
} else {
  // Development environment - use individual parameters
  sequelize = new Sequelize(
    dbConfig.database,
    dbConfig.username,
    dbConfig.password,
    {
      host: dbConfig.host,
      port: dbConfig.port,
      dialect: dbConfig.dialect,
      dialectOptions: dbConfig.dialectOptions,
      define: { underscored: true, freezeTableName: true },
      logging: dbConfig.logging || false
    }
  );
}

module.exports = { sequelize };
