const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Site } = require('../../../models');

// List sites, optionally filtered by client_id
router.get('/', auth(), async (req, res) => {
    const { client_id } = req.query;
    const where = {};
    if (client_id) where.client_id = client_id;
    try {
        const sites = await Site.findAll({ where });
        res.json(sites);
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

module.exports = router;
