const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Site, User } = require('../../../models');

// List sites, optionally filtered by client_id
router.get('/', auth(), async (req, res) => {
    const { client_id } = req.query;
    const where = {};
    if (client_id) where.client_id = client_id;
    try {
        const sites = await Site.findAll({ where, raw: true });
        
        // Enrich with client names
        const enrichedSites = await Promise.all(sites.map(async (site) => {
            let clientName = null;
            if (site.client_id) {
                const client = await User.findByPk(site.client_id, { raw: true });
                if (client) clientName = client.name;
            }
            return {
                ...site,
                client_name: clientName
            };
        }));
        
        res.json(enrichedSites);
    } catch (err) {
        res.status(500).json({ error: 'failed_to_load_sites', message: err.message });
    }
});

router.get('/:id', auth(), allow('CLIENT','ADMIN','OFFICER','CRO','FINANCE'), async (req,res)=>{
    const site = await Site.findByPk(req.params.id);
    if(!site) return res.status(404).json({ error:'not_found' });
    res.json(site);
});

router.patch('/:id', auth(), allow('ADMIN','CRO'), async (req,res)=>{
    const site = await Site.findByPk(req.params.id);
    if(!site) return res.status(404).json({ error:'not_found' });
    await site.update(req.body);
    res.json(site);
});

// Create new site
router.post('/', auth(), allow('ADMIN','CRO'), async (req,res)=>{
    try {
        const site = await Site.create(req.body);
        res.status(201).json(site);
    } catch (e) {
        res.status(400).json({ error: 'site_create_failed', message: e.message });
    }
});

// Update site (PUT)
router.put('/:id', auth(), allow('ADMIN','CRO'), async (req,res)=>{
    try {
        const site = await Site.findByPk(req.params.id);
        if(!site) return res.status(404).json({ error:'not_found' });
        await site.update(req.body);
        res.json(site);
    } catch (e) {
        res.status(400).json({ error: 'site_update_failed', message: e.message });
    }
});

// Delete site
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
    try {
        const site = await Site.findByPk(req.params.id);
        if(!site) return res.status(404).json({ error:'not_found' });
        await site.destroy();
        res.json({ message: 'Site deleted successfully' });
    } catch (e) {
        res.status(500).json({ error: 'site_delete_failed', message: e.message });
    }
});

// Bulk upsert sites (admin)
router.post('/bulk', auth(), allow('ADMIN','CRO'), async (req,res)=>{
    try {
        const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
        if (!items.length) return res.status(400).json({ error: 'no_items' });
        const rows = await Site.bulkCreate(items, { updateOnDuplicate: ['name','location','strength','rate_per_guard','agreement_start','agreement_end','area_officer_name','area_officer_phone','cro_name','cro_phone'] });
        res.status(201).json({ upserted: rows.length });
    } catch (e) {
        res.status(400).json({ error: 'site_bulk_failed', message: e.message });
    }
});

module.exports = router;
