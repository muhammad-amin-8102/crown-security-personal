
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { SalaryDisbursement } = require('../../../models');

router.get('/status', auth(), allow('CLIENT','ADMIN','FINANCE'), async (req,res)=>{
	const { siteId, month } = req.query; // YYYY-MM
	if(!siteId) return res.status(400).json({ error:'siteId_required' });
	const where = { site_id: siteId };
	if(month) where.month = new Date(`${month}-01`);
	const item = await SalaryDisbursement.findOne({ where, order:[['month','DESC']] });
	res.json(item || null);
});

// List disbursements
router.get('/', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	const { siteId, limit } = req.query;
	const where = {};
	if (siteId) where.site_id = siteId;
	const rows = await SalaryDisbursement.findAll({ where, order:[['month','DESC']], limit: Number(limit)||500 });
	res.json(rows);
});

module.exports = router;

// Create or update salary disbursement
router.post('/', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const body = req.body;
		const row = await SalaryDisbursement.create(body);
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'payroll_create_failed', message: e.message });
	}
});

// Bulk insert salary disbursements
router.post('/bulk', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const payload = items.map(it => ({
			...it,
			month: (typeof it.month === 'string') ? new Date(`${it.month.length === 7 ? it.month : it.month.substring(0,7)}-01`) : it.month,
		}));
		const rows = await SalaryDisbursement.bulkCreate(payload, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'payroll_bulk_failed', message: e.message });
	}
});
