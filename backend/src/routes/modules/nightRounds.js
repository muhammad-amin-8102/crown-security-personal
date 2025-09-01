
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { NightRound, Guard, User } = require('../../../models');

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
	const { siteId, from, to, limit } = req.query;
	const where = {};
	if (siteId) where.site_id = siteId;
	const rows = await NightRound.findAll({ 
		where, 
		order:[['date','DESC']], 
		limit: Number(limit)||500,
		raw: true
	});
	
	// Enrich each row with officer name
	const enrichedRows = await Promise.all(rows.map(async (row) => {
		let officerName = null;
		if (row.officer_id) {
			// First try Guard table
			const guard = await Guard.findByPk(row.officer_id, { raw: true });
			if (guard) {
				officerName = guard.name;
			} else {
				// Fallback to User table
				const user = await User.findByPk(row.officer_id, { raw: true });
				if (user) officerName = user.name;
			}
		}
		return {
			...row,
			officer_name: officerName
		};
	}));
	
	res.json(enrichedRows);
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
