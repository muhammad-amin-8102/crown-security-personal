
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Rating, Site, User } = require('../../../models');
const { Op } = require('sequelize');

router.post('/', auth(), allow('CLIENT'), async (req,res)=>{
	const { site_id, month, rating_value, nps_score } = req.body;
	const row = await Rating.create({ site_id, client_id: req.user.id, month: new Date(`${month}-01`), rating_value, nps_score });
	res.status(201).json(row);
});

router.get('/', auth(), allow('CLIENT','ADMIN','CRO'), async (req,res)=>{
	try {
		const { siteId } = req.query;
		const where = {};
		if (siteId) where.site_id = siteId;
		const rows = await Rating.findAll({ where, limit: 200, order:[['month','DESC']] });
		
		// Get unique client and site IDs
		const clientIds = [...new Set(rows.map(r => r.client_id).filter(Boolean))];
		const siteIds = [...new Set(rows.map(r => r.site_id).filter(Boolean))];
		
		// Fetch client names
		let clientNameById = {};
		if (clientIds.length) {
			const clients = await User.findAll({ where: { id: { [Op.in]: clientIds } }, attributes: ['id','name'] });
			clientNameById = Object.fromEntries(clients.map(c => [c.id, c.name]));
		}
		
		// Fetch site names
		let siteNameById = {};
		if (siteIds.length) {
			const sites = await Site.findAll({ where: { id: { [Op.in]: siteIds } }, attributes: ['id','name'] });
			siteNameById = Object.fromEntries(sites.map(s => [s.id, s.name]));
		}
		
		const out = rows.map(r => {
			const o = r.toJSON();
			o.client_name = clientNameById[o.client_id] || 'Unknown Client';
			o.site_name = siteNameById[o.site_id] || 'Unknown Site';
			return o;
		});
		
		res.json(out);
	} catch (e) {
		res.status(500).json({ error: 'ratings_list_failed', message: e.message });
	}
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

// Update rating
router.put('/:id', auth(), allow('ADMIN','CRO'), async (req,res)=>{
	try {
		const { id } = req.params;
		const body = { ...req.body };
		if (body.month && typeof body.month === 'string') {
			body.month = new Date(`${body.month}-01`);
		}
		const [updated] = await Rating.update(body, { where: { id } });
		if (updated === 0) {
			return res.status(404).json({ error: 'rating_not_found' });
		}
		const row = await Rating.findByPk(id);
		res.json(row);
	} catch (e) {
		res.status(400).json({ error: 'rating_update_failed', message: e.message });
	}
});

// Delete rating
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
	try {
		const { id } = req.params;
		const deleted = await Rating.destroy({ where: { id } });
		if (deleted === 0) {
			return res.status(404).json({ error: 'rating_not_found' });
		}
		res.json({ message: 'rating_deleted' });
	} catch (e) {
		res.status(400).json({ error: 'rating_delete_failed', message: e.message });
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
