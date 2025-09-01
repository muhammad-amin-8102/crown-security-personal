
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Spend, Site } = require('../../../models');
const { Op } = require('sequelize');

router.get('/all', auth(), allow('CLIENT','ADMIN','FINANCE'), async (req,res)=>{
	try {
		const { siteId, from, to } = req.query;
		const where = {};
		if(siteId) where.site_id = siteId;
		if(from || to) where.date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
		const rows = await Spend.findAll({ where, limit: 500, order:[['date','DESC']] });
		
		// Enrich with site names
		const siteIds = [...new Set(rows.map(r => r.site_id).filter(Boolean))];
		let siteNameById = {};
		if (siteIds.length) {
			const sites = await Site.findAll({ where: { id: { [Op.in]: siteIds } }, attributes: ['id','name'] });
			siteNameById = Object.fromEntries(sites.map(s => [s.id, s.name]));
		}

		const out = rows.map(r => {
			const o = r.toJSON();
			o.site_name = siteNameById[o.site_id] || 'Unknown Site';
			return o;
		});
		
		res.json(out);
	} catch (e) {
		res.status(500).json({ error: 'spend_list_failed', message: e.message });
	}
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

// Update single spend entry
router.put('/:id', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const { id } = req.params;
		const [updated] = await Spend.update(req.body, { where: { id } });
		if (updated === 0) {
			return res.status(404).json({ error: 'spend_not_found' });
		}
		const row = await Spend.findByPk(id);
		res.json(row);
	} catch (e) {
		res.status(400).json({ error: 'spend_update_failed', message: e.message });
	}
});

// Delete single spend entry
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
	try {
		const { id } = req.params;
		const deleted = await Spend.destroy({ where: { id } });
		if (deleted === 0) {
			return res.status(404).json({ error: 'spend_not_found' });
		}
		res.json({ message: 'spend_deleted' });
	} catch (e) {
		res.status(400).json({ error: 'spend_delete_failed', message: e.message });
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
