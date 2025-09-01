
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Complaint, Site, User } = require('../../../models');
const { Op } = require('sequelize');

router.post('/', auth(), allow('CLIENT'), async (req,res)=>{
	const { site_id, complaint_text } = req.body;
	const row = await Complaint.create({ site_id, client_id: req.user.id, complaint_text, status:'OPEN' });
	res.status(201).json(row);
});

router.get('/', auth(), allow('CLIENT','CRO','ADMIN'), async (req,res)=>{
	try {
		const { siteId, limit } = req.query;
		const where = {};
		if(siteId) where.site_id = siteId;
		const rows = await Complaint.findAll({ where, limit: Number(limit)||200, order:[['createdAt','DESC']] });
		
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
		res.status(500).json({ error: 'complaints_list_failed', message: e.message });
	}
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

// Update complaint
router.put('/:id', auth(), allow('ADMIN','CRO'), async (req,res)=>{
	try {
		const { id } = req.params;
		const [updated] = await Complaint.update(req.body, { where: { id } });
		if (updated === 0) {
			return res.status(404).json({ error: 'complaint_not_found' });
		}
		const row = await Complaint.findByPk(id);
		res.json(row);
	} catch (e) {
		res.status(400).json({ error: 'complaint_update_failed', message: e.message });
	}
});

// Delete complaint
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
	try {
		const { id } = req.params;
		const deleted = await Complaint.destroy({ where: { id } });
		if (deleted === 0) {
			return res.status(404).json({ error: 'complaint_not_found' });
		}
		res.json({ message: 'complaint_deleted' });
	} catch (e) {
		res.status(400).json({ error: 'complaint_delete_failed', message: e.message });
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
