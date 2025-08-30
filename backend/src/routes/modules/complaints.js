
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Complaint } = require('../../../models');

router.post('/', auth(), allow('CLIENT'), async (req,res)=>{
	const { site_id, complaint_text } = req.body;
	const row = await Complaint.create({ site_id, client_id: req.user.id, complaint_text, status:'OPEN' });
	res.status(201).json(row);
});

router.get('/', auth(), allow('CLIENT','CRO','ADMIN'), async (req,res)=>{
	const rows = await Complaint.findAll({ limit: 200, order:[['createdAt','DESC']] });
	res.json(rows);
});

module.exports = router;
