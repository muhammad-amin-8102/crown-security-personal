require('dotenv').config();

module.exports = {
  development: {
    username: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    dialect: "postgres",
    dialectOptions: { ssl: false },
    logging: false
  },
  production: {
    use_env_variable: "DATABASE_URL",
    dialect: "postgres",
    // dialectOptions: { ssl: false },
    dialectOptions: { 
      ssl: { require: true, rejectUnauthorized: false } 
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 60000,
      idle: 10000
    },
    retry: {
      max: 3
    },
    logging: true
  }
};
