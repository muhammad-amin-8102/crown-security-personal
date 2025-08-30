
const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { TrainingReport } = require('../../../models');

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
  const { siteId, from, to, limit } = req.query;
  const where = {};
  if (siteId) where.site_id = siteId;
  const rows = await TrainingReport.findAll({ where, order:[['date','DESC']], limit: Number(limit)||500 });
  res.json(rows);
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
