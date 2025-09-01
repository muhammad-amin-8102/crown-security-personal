
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Attendance, User, Guard, Site } = require('../../../models');
const { Op } = require('sequelize');

router.get('/', auth(), allow('CLIENT','ADMIN','OFFICER'), async (req,res)=>{
	const { siteId, from, to, status } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(status) where.status = status;
	if(from || to) where.date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const rows = await Attendance.findAll({ where, limit: 500, order:[['date','DESC']] });
	try {
		// Enrich with guard names
		const guardIds = [...new Set(rows.map(r => r.guard_id).filter(Boolean))];
		let guardNameById = {};
		if (guardIds.length) {
			const guards = await Guard.findAll({ where: { id: { [Op.in]: guardIds } }, attributes: ['id','name'] });
			guardNameById = Object.fromEntries(guards.map(g => [g.id, g.name]));
			// Fallback to Users table if guard not found in Guards
			const missing = guardIds.filter(id => !guardNameById[id]);
			if (missing.length) {
				const users = await User.findAll({ where: { id: { [Op.in]: missing } }, attributes: ['id','name'] });
				users.forEach(u => { guardNameById[u.id] = u.name; });
			}
		}

		// Enrich with site names
		const siteIds = [...new Set(rows.map(r => r.site_id).filter(Boolean))];
		let siteNameById = {};
		if (siteIds.length) {
			const sites = await Site.findAll({ where: { id: { [Op.in]: siteIds } }, attributes: ['id','name'] });
			siteNameById = Object.fromEntries(sites.map(s => [s.id, s.name]));
		}

		const out = rows.map(r => {
			const o = r.toJSON();
			o.guard_name = guardNameById[o.guard_id] || o.guard_id;
			o.site_name = siteNameById[o.site_id] || 'Unknown Site';
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

// Update single attendance row
router.put('/:id', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
	try {
		const { id } = req.params;
		const body = req.body;
		const [updated] = await Attendance.update(body, { where: { id } });
		if (updated === 0) {
			return res.status(404).json({ error: 'attendance_not_found' });
		}
		const row = await Attendance.findByPk(id);
		res.json(row);
	} catch (e) {
		res.status(400).json({ error: 'attendance_update_failed', message: e.message });
	}
});

// Delete single attendance row
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
	try {
		const { id } = req.params;
		const deleted = await Attendance.destroy({ where: { id } });
		if (deleted === 0) {
			return res.status(404).json({ error: 'attendance_not_found' });
		}
		res.json({ message: 'attendance_deleted' });
	} catch (e) {
		res.status(400).json({ error: 'attendance_delete_failed', message: e.message });
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
