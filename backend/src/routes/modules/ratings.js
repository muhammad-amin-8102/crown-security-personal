
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Rating } = require('../../../models');

router.post('/', auth(), allow('CLIENT'), async (req,res)=>{
	const { site_id, month, rating_value, nps_score } = req.body;
	const row = await Rating.create({ site_id, client_id: req.user.id, month: new Date(`${month}-01`), rating_value, nps_score });
	res.status(201).json(row);
});

router.get('/', auth(), allow('CLIENT','ADMIN','CRO'), async (req,res)=>{
	const rows = await Rating.findAll({ limit: 200, order:[['month','DESC']] });
	res.json(rows);
});

module.exports = router;
