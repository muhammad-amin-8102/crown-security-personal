
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Attendance, User, Guard } = require('../../../models');
const { Op } = require('sequelize');

router.get('/', auth(), allow('CLIENT','ADMIN','OFFICER'), async (req,res)=>{
	const { siteId, from, to, status } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(status) where.status = status;
	if(from || to) where.date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const rows = await Attendance.findAll({ where, limit: 500, order:[['date','DESC']] });
	try {
		const guardIds = [...new Set(rows.map(r => r.guard_id).filter(Boolean))];
		let nameById = {};
		if (guardIds.length) {
			const guards = await Guard.findAll({ where: { id: { [Op.in]: guardIds } }, attributes: ['id','name'] });
			nameById = Object.fromEntries(guards.map(g => [g.id, g.name]));
			// Fallback to Users table if guard not found in Guards
			const missing = guardIds.filter(id => !nameById[id]);
			if (missing.length) {
				const users = await User.findAll({ where: { id: { [Op.in]: missing } }, attributes: ['id','name'] });
				users.forEach(u => { nameById[u.id] = u.name; });
			}
		}
		const out = rows.map(r => {
			const o = r.toJSON();
			o.guard_name = nameById[o.guard_id] || o.guard_id;
			return o;
		});
		return res.json(out);
	} catch (e) {
		return res.json(rows);
	}
});

// Create single attendance row
router.post('/', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
	try {
		const body = req.body;
		const row = await Attendance.create(body);
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'attendance_create_failed', message: e.message });
	}
});

// Bulk insert/update attendance
router.post('/bulk', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const rows = await Attendance.bulkCreate(items, { validate: true, ignoreDuplicates: false });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'attendance_bulk_failed', message: e.message });
	}
});

module.exports = router;
