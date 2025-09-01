
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { NightRound, Guard, User, Site } = require('../../../models');
const { Op } = require('sequelize');

router.get('/latest', auth(), allow('CLIENT','ADMIN','OFFICER','CRO'), async (req,res)=>{
	const { siteId } = req.query;
	if(!siteId) return res.status(400).json({ error:'siteId_required' });
	const item = await NightRound.findOne({ 
		where: { site_id: siteId }, 
		order:[['date','DESC']],
		raw: true
	});
	if (!item) return res.json(null);
	
	// Try to enrich with officer name from Guard or User table
	let officerName = null;
	if (item.officer_id) {
		// First try Guard table
		const guard = await Guard.findByPk(item.officer_id, { raw: true });
		if (guard) {
			officerName = guard.name;
		} else {
			// Fallback to User table
			const user = await User.findByPk(item.officer_id, { raw: true });
			if (user) officerName = user.name;
		}
	}
	
	res.json({
		...item,
		officer_name: officerName
	});
});

// List night rounds
router.get('/', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
	try {
		const { siteId, from, to, limit } = req.query;
		const where = {};
		if (siteId) where.site_id = siteId;
		const rows = await NightRound.findAll({ 
			where, 
			order:[['date','DESC']], 
			limit: Number(limit)||500,
			raw: true
		});
		
		// Get unique officer and site IDs
		const officerIds = [...new Set(rows.map(r => r.officer_id).filter(Boolean))];
		const siteIds = [...new Set(rows.map(r => r.site_id).filter(Boolean))];
		
		// Fetch officer names
		let officerNameById = {};
		if (officerIds.length) {
			const guards = await Guard.findAll({ where: { id: { [Op.in]: officerIds } }, attributes: ['id','name'] });
			officerNameById = Object.fromEntries(guards.map(g => [g.id, g.name]));
			// Fallback to Users table
			const missing = officerIds.filter(id => !officerNameById[id]);
			if (missing.length) {
				const users = await User.findAll({ where: { id: { [Op.in]: missing } }, attributes: ['id','name'] });
				users.forEach(u => { officerNameById[u.id] = u.name; });
			}
		}
		
		// Fetch site names
		let siteNameById = {};
		if (siteIds.length) {
			const sites = await Site.findAll({ where: { id: { [Op.in]: siteIds } }, attributes: ['id','name'] });
			siteNameById = Object.fromEntries(sites.map(s => [s.id, s.name]));
		}
		
		const enrichedRows = rows.map(row => ({
			...row,
			officer_name: officerNameById[row.officer_id] || row.officer_id,
			site_name: siteNameById[row.site_id] || 'Unknown Site'
		}));
		
		res.json(enrichedRows);
	} catch (e) {
		res.status(500).json({ error: 'nightrounds_list_failed', message: e.message });
	}
});

// Create a new night round entry
router.post('/', auth(), allow('ADMIN','OFFICER'), async (req,res)=>{
	try {
		const row = await NightRound.create(req.body);
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'nightround_create_failed', message: e.message });
	}
});

// Update night round entry
router.put('/:id', auth(), allow('ADMIN','OFFICER'), async (req,res)=>{
	try {
		const { id } = req.params;
		const [updated] = await NightRound.update(req.body, { where: { id } });
		if (updated === 0) {
			return res.status(404).json({ error: 'nightround_not_found' });
		}
		const row = await NightRound.findByPk(id);
		res.json(row);
	} catch (e) {
		res.status(400).json({ error: 'nightround_update_failed', message: e.message });
	}
});

// Delete night round entry
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
	try {
		const { id } = req.params;
		const deleted = await NightRound.destroy({ where: { id } });
		if (deleted === 0) {
			return res.status(404).json({ error: 'nightround_not_found' });
		}
		res.json({ message: 'nightround_deleted' });
	} catch (e) {
		res.status(400).json({ error: 'nightround_delete_failed', message: e.message });
	}
});

// Bulk insert night round entries
router.post('/bulk', auth(), allow('ADMIN','OFFICER'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const rows = await NightRound.bulkCreate(items, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'nightround_bulk_failed', message: e.message });
	}
});

module.exports = router;
