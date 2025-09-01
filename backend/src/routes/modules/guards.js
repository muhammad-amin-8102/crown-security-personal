const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Guard, Site } = require('../../../models');

// List all guards
router.get('/', auth(), allow('ADMIN', 'OFFICER', 'CRO'), async (req, res) => {
  try {
    const { siteId } = req.query;
    const where = {};
    if (siteId) where.site_id = siteId;
    
    const guards = await Guard.findAll({
      where,
      order: [['createdAt', 'DESC']],
      raw: true
    });
    
    // Enrich with site names
    const enrichedGuards = await Promise.all(guards.map(async (guard) => {
      let siteName = null;
      if (guard.site_id) {
        const site = await Site.findByPk(guard.site_id, { raw: true });
        if (site) siteName = site.name;
      }
      return {
        ...guard,
        site_name: siteName
      };
    }));
    
    res.json(enrichedGuards);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get single guard
router.get('/:id', auth(), allow('ADMIN', 'OFFICER', 'CRO'), async (req, res) => {
  try {
    const guard = await Guard.findByPk(req.params.id);
    if (!guard) return res.status(404).json({ error: 'Guard not found' });
    res.json(guard);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create guard
router.post('/', auth(), allow('ADMIN', 'OFFICER'), async (req, res) => {
  try {
    const guard = await Guard.create(req.body);
    res.status(201).json(guard);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update guard
router.put('/:id', auth(), allow('ADMIN', 'OFFICER'), async (req, res) => {
  try {
    const guard = await Guard.findByPk(req.params.id);
    if (!guard) return res.status(404).json({ error: 'Guard not found' });
    
    await guard.update(req.body);
    res.json(guard);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete guard
router.delete('/:id', auth(), allow('ADMIN'), async (req, res) => {
  try {
    const guard = await Guard.findByPk(req.params.id);
    if (!guard) return res.status(404).json({ error: 'Guard not found' });
    
    await guard.destroy();
    res.json({ message: 'Guard deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Bulk create guards
router.post('/bulk', auth(), allow('ADMIN', 'OFFICER'), async (req, res) => {
  try {
    const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
    if (!items.length) return res.status(400).json({ error: 'no_items' });
    
    const guards = await Guard.bulkCreate(items, { validate: true });
    res.status(201).json({ inserted: guards.length });
  } catch (error) {
    res.status(400).json({ error: 'bulk_create_failed', message: error.message });
  }
});

module.exports = router;
