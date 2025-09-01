
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { TrainingReport, Site } = require('../../../models');
const { Op } = require('sequelize');

router.get('/latest', auth(), async (req, res) => {
  try {
    const { siteId } = req.query;
    const latestTraining = await TrainingReport.findOne({
      where: { site_id: siteId },
      order: [['date', 'DESC']],
    });
    if (latestTraining) {
      res.json({
        ...latestTraining.toJSON(),
        // Prefer `topics` (comma-separated), fallback to legacy `topics_covered`
        topicsCovered: (() => {
          const list = (latestTraining.topics || latestTraining.topics_covered || '')
            ?.toString()
            .split(',')
            .map((s) => (s || '').toString().trim())
            .filter((s) => s.length > 0);
          return Array.isArray(list) ? list.length : 0;
        })(),
      });
    } else {
      res.json(null);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// List training reports
router.get('/', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
  try {
    const { siteId, from, to, limit } = req.query;
    const where = {};
    if (siteId) where.site_id = siteId;
    const rows = await TrainingReport.findAll({ where, order:[['date','DESC']], limit: Number(limit)||500 });
    
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
    res.status(500).json({ error: 'training_list_failed', message: e.message });
  }
});

module.exports = router;

// Create a training report
router.post('/', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
  try {
    const row = await TrainingReport.create(req.body);
    res.status(201).json(row);
  } catch (e) {
    res.status(400).json({ error: 'training_create_failed', message: e.message });
  }
});

// Update training report
router.put('/:id', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
  try {
    const { id } = req.params;
    const [updated] = await TrainingReport.update(req.body, { where: { id } });
    if (updated === 0) {
      return res.status(404).json({ error: 'training_not_found' });
    }
    const row = await TrainingReport.findByPk(id);
    res.json(row);
  } catch (e) {
    res.status(400).json({ error: 'training_update_failed', message: e.message });
  }
});

// Delete training report
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
  try {
    const { id } = req.params;
    const deleted = await TrainingReport.destroy({ where: { id } });
    if (deleted === 0) {
      return res.status(404).json({ error: 'training_not_found' });
    }
    res.json({ message: 'training_deleted' });
  } catch (e) {
    res.status(400).json({ error: 'training_delete_failed', message: e.message });
  }
});

// Bulk insert training reports
router.post('/bulk', auth(), allow('ADMIN','OFFICER','CRO'), async (req,res)=>{
  try {
    const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
    if (!items.length) return res.status(400).json({ error: 'no_items' });
    const rows = await TrainingReport.bulkCreate(items, { validate: true });
    res.status(201).json({ inserted: rows.length });
  } catch (e) {
    res.status(400).json({ error: 'training_bulk_failed', message: e.message });
  }
});
