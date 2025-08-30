
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Spend } = require('../../../models');
const { Op } = require('sequelize');

router.get('/', auth(), allow('CLIENT','ADMIN','FINANCE'), async (req,res)=>{
	const { siteId, from, to } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(from || to) where.date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const rows = await Spend.findAll({ where, limit: 500, order:[['date','DESC']] });
	res.json(rows);
});

module.exports = router;
