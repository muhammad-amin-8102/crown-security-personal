
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Bill, Site } = require('../../../models');
const { Op } = require('sequelize');

// Get all bills with site information
router.get('/', auth(), allow('CLIENT','ADMIN','FINANCE','CRO'), async (req, res) => {
	try {
		const { siteId, from, to, status } = req.query;
		const where = {};
		if (siteId) where.site_id = siteId;
		if (status) where.status = status;
		if (from || to) where.due_date = { [Op.between]: [from || '1970-01-01', to || '2999-12-31'] };
		
		const bills = await Bill.findAll({ 
			where, 
			include: [{
				model: Site,
				attributes: ['id', 'name', 'location']
			}],
			order: [['due_date', 'ASC']] 
		});
		
		res.json(bills);
	} catch (error) {
		res.status(500).json({ error: 'failed_to_fetch_bills', message: error.message });
	}
});

// Get all sites for dropdown
router.get('/sites', auth(), allow('CLIENT','ADMIN','FINANCE','CRO'), async (req, res) => {
	try {
		console.log('Fetching sites for dropdown...');
		console.log('Site model:', Site);
		
		const sites = await Site.findAll({
			attributes: ['id', 'name', 'location'],
			order: [['name', 'ASC']]
		});
		
		console.log('Sites found:', sites.length);
		res.json(sites);
	} catch (error) {
		console.error('Sites fetch error:', error);
		res.status(500).json({ error: 'failed_to_fetch_sites', message: error.message });
	}
});

// Get single bill by ID
router.get('/:id', auth(), allow('CLIENT','ADMIN','FINANCE','CRO'), async (req, res) => {
	try {
		const bill = await Bill.findByPk(req.params.id, {
			include: [{
				model: Site,
				attributes: ['id', 'name', 'location']
			}]
		});
		
		if (!bill) {
			return res.status(404).json({ error: 'bill_not_found' });
		}
		
		res.json(bill);
	} catch (error) {
		res.status(500).json({ error: 'failed_to_fetch_bill', message: error.message });
	}
});

router.get('/soa', auth(), allow('CLIENT','ADMIN','FINANCE','CRO'), async (req,res)=>{
	const { siteId, from, to } = req.query;
	const where = {};
	if(siteId) where.site_id = siteId;
	if(from || to) where.due_date = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };
	
	const rows = await Bill.findAll({ 
		where, 
		include: [{
			model: Site,
			attributes: ['id', 'name', 'location']
		}],
		order:[['due_date','ASC']] 
	});
	
	const outstanding = rows.filter(r => r.status === 'OUTSTANDING').reduce((s,r)=>s+Number(r.amount),0);
	res.json({ items: rows, outstanding });
});

// Create single bill
router.post('/', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const bill = await Bill.create(req.body);
		
		// Fetch the created bill with site information
		const billWithSite = await Bill.findByPk(bill.id, {
			include: [{
				model: Site,
				attributes: ['id', 'name', 'location']
			}]
		});
		
		res.status(201).json(billWithSite);
	} catch (e) {
		res.status(400).json({ error: 'bill_create_failed', message: e.message });
	}
});

// Update bill
router.put('/:id', auth(), allow('ADMIN','FINANCE'), async (req, res) => {
	try {
		const bill = await Bill.findByPk(req.params.id);
		
		if (!bill) {
			return res.status(404).json({ error: 'bill_not_found' });
		}
		
		await bill.update(req.body);
		
		// Fetch updated bill with site information
		const updatedBill = await Bill.findByPk(bill.id, {
			include: [{
				model: Site,
				attributes: ['id', 'name', 'location']
			}]
		});
		
		res.json(updatedBill);
	} catch (error) {
		res.status(400).json({ error: 'bill_update_failed', message: error.message });
	}
});

// Delete bill
router.delete('/:id', auth(), allow('ADMIN','FINANCE'), async (req, res) => {
	try {
		const bill = await Bill.findByPk(req.params.id);
		
		if (!bill) {
			return res.status(404).json({ error: 'bill_not_found' });
		}
		
		await bill.destroy();
		res.json({ message: 'bill_deleted_successfully', id: req.params.id });
	} catch (error) {
		res.status(500).json({ error: 'failed_to_delete_bill', message: error.message });
	}
});

// Bulk insert bills
router.post('/bulk', auth(), allow('ADMIN','FINANCE'), async (req,res)=>{
	try {
		const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
		if (!items.length) return res.status(400).json({ error: 'no_items' });
		const rows = await Bill.bulkCreate(items, { validate: true });
		res.status(201).json({ inserted: rows.length });
	} catch (e) {
		res.status(400).json({ error: 'bill_bulk_failed', message: e.message });
	}
});

module.exports = router;
