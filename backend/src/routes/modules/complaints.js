
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Complaint } = require('../../../models');

router.post('/', auth(), allow('CLIENT'), async (req,res)=>{
	const { site_id, complaint_text } = req.body;
	const row = await Complaint.create({ site_id, client_id: req.user.id, complaint_text, status:'OPEN' });
	res.status(201).json(row);
});

router.get('/', auth(), allow('CLIENT','CRO','ADMIN'), async (req,res)=>{
	const { siteId, limit } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	const rows = await Complaint.findAll({ where, limit: Number(limit)||200, order:[['createdAt','DESC']] });
	res.json(rows);
});

// Admin create complaint on behalf of client
router.post('/admin', auth(), allow('ADMIN','CRO'), async (req,res)=>{
	try {
		const { site_id, complaint_text, client_id, status } = req.body;
		const row = await Complaint.create({ site_id, client_id, complaint_text, status: status || 'OPEN' });
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'complaint_create_failed', message: e.message });
	}
});

// Bulk insert complaints
router.post('/bulk', auth(), allow('ADMIN','CRO'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const rows = await Complaint.bulkCreate(items, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'complaint_bulk_failed', message: e.message });
	}
});

module.exports = router;
