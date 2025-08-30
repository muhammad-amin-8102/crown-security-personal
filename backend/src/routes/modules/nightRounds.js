
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { NightRound } = require('../../../models');

router.get('/latest', auth(), allow('CLIENT','ADMIN','OFFICER','CRO'), async (req,res)=>{
	const { siteId } = req.query;
	if(!siteId) return res.status(400).json({ error:'siteId_required' });
	const item = await NightRound.findOne({ where: { site_id: siteId }, order:[['date','DESC']] });
	res.json(item || null);
});

module.exports = router;
