
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Bill } = require('../../../models');
const { Op } = require('sequelize');

router.get('/soa', auth(), allow('CLIENT','ADMIN','FINANCE','CRO'), async (req,res)=>{
	const { siteId, from, to } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(from || to) where.due_date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	const rows = await Bill.findAll({ where, order:[['due_date','ASC']] });
	const outstanding = rows.filter(r => r.status === 'OUTSTANDING').reduce((s,r)=>s+Number(r.amount),0);
	res.json({ items: rows, outstanding });
});

module.exports = router;
