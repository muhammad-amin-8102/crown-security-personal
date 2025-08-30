const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const routes = require('./routes');

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('tiny'));

app.get('/api/health', (_req, res)=>res.json({ ok:true, name:'Crown Security', ts:Date.now() }));
app.use('/api/v1', routes);

module.exports = app;
