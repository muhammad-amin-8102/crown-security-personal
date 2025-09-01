const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { Shift, Attendance, Spend, SalaryDisbursement, Bill } = require('../../../models');
const { Op } = require('sequelize');


router.get('/summary', auth(), allow('CLIENT','ADMIN','OFFICER','CRO','FINANCE'), async (req,res)=>{
  const { siteId, from, to } = req.query;
  if(!siteId || siteId === 'your-site-id') {
    return res.status(200).json({ error: 'no_site_assigned', message: 'No site assigned to your account.' });
  }
  const range = { [Op.between]: [ from || '1970-01-01', to || '2999-12-31' ] };

  try {
    const shifts = await Shift.findAll({ where: { site_id: siteId, date: range }, raw: true });
    const shiftWiseCount = {};
    for(const s of shifts){
      const day = s.date.toISOString().slice(0,10);
      shiftWiseCount[day] ??= { MORNING:0, EVENING:0, NIGHT:0 };
      shiftWiseCount[day][s.shift_type] += s.guard_count;
    }

  const att = await Attendance.findAll({ where: { site_id: siteId, date: range }, raw: true });
    const tillDateAttendance = { PRESENT:0, ABSENT:0, LEAVE:0 };
    att.forEach(a => tillDateAttendance[a.status] = (tillDateAttendance[a.status]||0)+1);

  const spendSum = await Spend.sum('amount', { where: { site_id: siteId, date: range }});
    const salary = await SalaryDisbursement.findOne({ where: { site_id: siteId }, order: [['month','DESC']] });
    const outstandingBills = await Bill.findAll({ where: { site_id: siteId, status: 'OUTSTANDING' }, order: [['due_date','ASC']], limit: 10 });

    res.json({
      shiftWiseCount,
      tillDateAttendance,
      tillDateSpend: Number(spendSum || 0),
      salaryDisbursement: salary,
      outstandingBills
    });
  } catch (err) {
    res.status(500).json({ error: 'dashboard_error', message: err.message });
  }
});

module.exports = router;
