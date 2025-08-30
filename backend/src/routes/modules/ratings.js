
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Rating } = require('../../../models');

router.post('/', auth(), allow('CLIENT'), async (req,res)=>{
	const { site_id, month, rating_value, nps_score } = req.body;
	const row = await Rating.create({ site_id, client_id: req.user.id, month: new Date(`${month}-01`), rating_value, nps_score });
	res.status(201).json(row);
});

router.get('/', auth(), allow('CLIENT','ADMIN','CRO'), async (req,res)=>{
		const { siteId } = req.query;
		const where = {};
		if (siteId) where.site_id = siteId;
		const rows = await Rating.findAll({ where, limit: 200, order:[['month','DESC']] });
		res.json(rows);
});

// Admin create rating on behalf of client
router.post('/admin', auth(), allow('ADMIN','CRO'), async (req,res)=>{
	try {
		const { site_id, month, rating_value, nps_score, client_id } = req.body;
		const row = await Rating.create({ site_id, client_id, month: new Date(`${month}-01`), rating_value, nps_score });
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'rating_create_failed', message: e.message });
	}
});

// Bulk insert ratings
router.post('/bulk', auth(), allow('ADMIN','CRO'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const payload = items.map(it => ({ ...it, month: new Date(`${it.month}-01`) }));
		const rows = await Rating.bulkCreate(payload, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'rating_bulk_failed', message: e.message });
	}
});

module.exports = router;
