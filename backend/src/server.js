require('dotenv').config();
const app = require('./app');
const { sequelize } = require('./db');

const port = process.env.PORT || 8080;

(async () => {
  try {
    await sequelize.authenticate();
    console.log('DB connected');
    app.listen(port, () => console.log(`API listening on :${port}`));
  } catch (e) {
    console.error('Startup error:', e);
    process.exit(1);
  }
})();
