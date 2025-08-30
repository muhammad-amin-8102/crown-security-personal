
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { SalaryDisbursement } = require('../../../models');

router.get('/status', auth(), allow('CLIENT','ADMIN','FINANCE'), async (req,res)=>{
	const { siteId, month } = req.query; // YYYY-MM
	if(!siteId) return res.status(400).json({ error:'siteId_required' });
	const where = { site_id: siteId };
	if(month) where.month = new Date(`${month}-01`);
	const item = await SalaryDisbursement.findOne({ where, order:[['month','DESC']] });
	res.json(item || null);
});

module.exports = router;
