
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { SalaryDisbursement, Site } = require('../../../models');
const { Op } = require('sequelize');

router.get('/status', auth(), allow('CLIENT','ADMIN','FINANCE'), async (req,res)=>{
	const { siteId, month } = req.query; // YYYY-MM
	if(!siteId) return res.status(400).json({ error:'siteId_required' });
	const where = { site_id: siteId };
	if(month) where.month = new Date(`${month}-01`);
	const item = await SalaryDisbursement.findOne({ where, order:[['month','DESC']] });
	res.json(item || null);
});

// List disbursements
router.get('/', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const { siteId, limit } = req.query;
		const where = {};
		if (siteId) where.site_id = siteId;
		const rows = await SalaryDisbursement.findAll({ where, order:[['month','DESC']], limit: Number(limit)||500 });
		
		// Enrich with site names
		const siteIds = [...new Set(rows.map(r => r.site_id).filter(Boolean))];
		let siteNameById = {};
		if (siteIds.length) {
			const sites = await Site.findAll({ where: { id: { [Op.in]: siteIds } }, attributes: ['id','name'] });
			siteNameById = Object.fromEntries(sites.map(s => [s.id, s.name]));
		}

		const out = rows.map(r => {
			const o = r.toJSON();
			o.site_name = siteNameById[o.site_id] || 'Unknown Site';
			return o;
		});
		
		res.json(out);
	} catch (e) {
		res.status(500).json({ error: 'payroll_list_failed', message: e.message });
	}
});

module.exports = router;

// Create or update salary disbursement
router.post('/', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const body = req.body;
		const row = await SalaryDisbursement.create(body);
		res.status(201).json(row);
	} catch (e) {
		res.status(400).json({ error: 'payroll_create_failed', message: e.message });
	}
});

// Update salary disbursement
router.put('/:id', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const { id } = req.params;
		const [updated] = await SalaryDisbursement.update(req.body, { where: { id } });
		if (updated === 0) {
			return res.status(404).json({ error: 'payroll_not_found' });
		}
		const row = await SalaryDisbursement.findByPk(id);
		res.json(row);
	} catch (e) {
		res.status(400).json({ error: 'payroll_update_failed', message: e.message });
	}
});

// Delete salary disbursement
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
	try {
		const { id } = req.params;
		const deleted = await SalaryDisbursement.destroy({ where: { id } });
		if (deleted === 0) {
			return res.status(404).json({ error: 'payroll_not_found' });
		}
		res.json({ message: 'payroll_deleted' });
	} catch (e) {
		res.status(400).json({ error: 'payroll_delete_failed', message: e.message });
	}
});

// Bulk insert salary disbursements
router.post('/bulk', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const payload = items.map(it => ({
			...it,
			month: (typeof it.month === 'string') ? new Date(`${it.month.length === 7 ? it.month : it.month.substring(0,7)}-01`) : it.month,
		}));
		const rows = await SalaryDisbursement.bulkCreate(payload, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'payroll_bulk_failed', message: e.message });
	}
});
