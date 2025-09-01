const router = require('express').Router();

router.use('/auth', require('./modules/auth'));
router.use('/users', require('./modules/users'));
router.use('/guards', require('./modules/guards'));
router.use('/sites', require('./modules/sites'));
router.use('/reports', require('./modules/reports'));
router.use('/attendance', require('./modules/attendance'));
router.use('/spend', require('./modules/spend'));
router.use('/night-rounds', require('./modules/nightRounds'));
router.use('/training', require('./modules/training'));
router.use('/payroll', require('./modules/payroll'));
router.use('/complaints', require('./modules/complaints'));
router.use('/ratings', require('./modules/ratings'));
router.use('/billing', require('./modules/billing'));
router.use('/bills', require('./modules/billing')); // Alias for bills
router.use('/shifts', require('./modules/shifts'));

module.exports = router;

// Catch-all for SPA routes (Flutter web)
const path = require('path');
router.get('*', (req, res) => {
	res.sendFile(path.resolve(__dirname, '../../../app/crown_security/web/index.html'));
});
