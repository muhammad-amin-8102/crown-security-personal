
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Spend } = require('../../../models');
const { Op } = require('sequelize');

router.get('/all', auth(), allow('CLIENT','ADMIN','FINANCE'), async (req,res)=>{
	const { siteId, from, to } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(from || to) where.date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const rows = await Spend.findAll({ where, limit: 500, order:[['date','DESC']] });
	res.json(rows);
});

router.get('/', auth(), allow('CLIENT','ADMIN','FINANCE'), async (req,res)=>{
	const { siteId, from, to } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(from || to) where.date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const totalSpend = await Spend.sum('amount', { where });
	res.json({ totalSpend });
});

// Create single spend entry
router.post('/', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const row = await Spend.create(req.body);
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'spend_create_failed', message: e.message });
	}
});

// Bulk insert spend entries
router.post('/bulk', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const rows = await Spend.bulkCreate(items, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'spend_bulk_failed', message: e.message });
	}
});

module.exports = router;
