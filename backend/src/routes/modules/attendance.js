
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Attendance } = require('../../../models');
const { Op } = require('sequelize');

router.get('/', auth(), allow('CLIENT','ADMIN','OFFICER'), async (req,res)=>{
	const { siteId, from, to, status } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(status) where.status = status;
	if(from || to) where.date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const rows = await Attendance.findAll({ where, limit: 500, order:[['date','DESC']] });
	res.json(rows);
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
