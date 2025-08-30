
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

module.exports = router;
