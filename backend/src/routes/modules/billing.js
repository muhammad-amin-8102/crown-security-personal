
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Bill } = require('../../../models');
const { Op } = require('sequelize');

router.get('/soa', auth(), allow('CLIENT','ADMIN','FINANCE','CRO'), async (req,res)=>{
	const { siteId, from, to } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(from || to) where.due_date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const rows = await Bill.findAll({ where, order:[['due_date','ASC']] });
	const outstanding = rows.filter(r => r.status === 'OUTSTANDING').reduce((s,r)=>s+Number(r.amount),0);
	res.json({ items: rows, outstanding });
});

// Create single bill
router.post('/', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const row = await Bill.create(req.body);
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'bill_create_failed', message: e.message });
	}
});

// Bulk insert bills
router.post('/bulk', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const rows = await Bill.bulkCreate(items, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'bill_bulk_failed', message: e.message });
	}
});

module.exports = router;
