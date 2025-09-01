const express = require('express');
const { Shift, Site } = require('../../../models');
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Op } = require('sequelize');

const router = express.Router();

// Get aggregated shifts for the latest date for a site
router.get('/', auth(), async (req, res) => {
  try {
    const { siteId } = req.query;
    if (!siteId) return res.status(400).json({ error: 'siteId_required' });
    const rows = await Shift.findAll({
      where: { site_id: siteId },
      order: [['date', 'DESC']],
      limit: 2000,
    });
    if (!rows.length) return res.json([]);
    const latestDate = rows[0].date;
    const sameDay = rows.filter(r => new Date(r.date).toDateString() === new Date(latestDate).toDateString());
    const agg = sameDay.reduce((acc, r) => {
      acc[r.shift_type] = (acc[r.shift_type] || 0) + (r.guard_count || 0);
      return acc;
    }, {});
    const list = Object.entries(agg).map(([shift, guards]) => ({ shift, guards }));
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get latest shift report for a site
router.get('/latest', auth(), async (req, res) => {
  try {
    const { siteId } = req.query;
    if (!siteId) return res.status(400).json({ error: 'siteId_required' });
    const rows = await Shift.findAll({
      where: { site_id: siteId },
      order: [['date', 'DESC']],
      limit: 2000,
    });
    if (!rows.length) return res.json({ shiftWiseCount: 0, shiftBreakdown: [] });
    
    const latestDate = rows[0].date;
    const sameDay = rows.filter(r => new Date(r.date).toDateString() === new Date(latestDate).toDateString());
    
    // Calculate breakdown by shift type
    const agg = sameDay.reduce((acc, r) => {
      acc[r.shift_type] = (acc[r.shift_type] || 0) + (r.guard_count || 0);
      return acc;
    }, {});
    
    const shiftBreakdown = Object.entries(agg).map(([shift, guards]) => ({ shift, guards }));
    const shiftWiseCount = sameDay.reduce((acc, r) => acc + (r.guard_count || 0), 0);
    
    res.json({ shiftWiseCount, shiftBreakdown, latestDate });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;

// Raw list of shifts
router.get('/list/all', auth(), allow('ADMIN','OFFICER'), async (req,res)=>{
  try {
    const { siteId, from, to, limit } = req.query;
    const where = {};
    if (siteId) where.site_id = siteId;
    // Optionally filter by date in future if added
    const rows = await Shift.findAll({ where, order:[['date','DESC']], limit: Number(limit)||1000 });
    
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
    res.status(500).json({ error: 'shifts_list_failed', message: e.message });
  }
});

// Create single shift
router.post('/', auth(), allow('ADMIN','OFFICER'), async (req,res)=>{
  try {
    const row = await Shift.create(req.body);
    res.status(201).json(row);
  } catch (e) {
    res.status(400).json({ error: 'shift_create_failed', message: e.message });
  }
});

// Update single shift
router.put('/:id', auth(), allow('ADMIN','OFFICER'), async (req,res)=>{
  try {
    const { id } = req.params;
    const [updated] = await Shift.update(req.body, { where: { id } });
    if (updated === 0) {
      return res.status(404).json({ error: 'shift_not_found' });
    }
    const row = await Shift.findByPk(id);
    res.json(row);
  } catch (e) {
    res.status(400).json({ error: 'shift_update_failed', message: e.message });
  }
});

// Delete single shift
router.delete('/:id', auth(), allow('ADMIN'), async (req,res)=>{
  try {
    const { id } = req.params;
    const deleted = await Shift.destroy({ where: { id } });
    if (deleted === 0) {
      return res.status(404).json({ error: 'shift_not_found' });
    }
    res.json({ message: 'shift_deleted' });
  } catch (e) {
    res.status(400).json({ error: 'shift_delete_failed', message: e.message });
  }
});

// Bulk insert shifts
router.post('/bulk', auth(), allow('ADMIN','OFFICER'), async (req,res)=>{
  try {
    const items = Array.isArray(req.body) ? req.body : (req.body.items || []);
    if (!items.length) return res.status(400).json({ error: 'no_items' });
    const rows = await Shift.bulkCreate(items, { validate: true });
    res.status(201).json({ inserted: rows.length });
  } catch (e) {
    res.status(400).json({ error: 'shift_bulk_failed', message: e.message });
  }
});
