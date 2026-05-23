const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/laporanController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { handleUpload } = require('../middleware/uploadMiddleware');

router.get('/distribusi', authenticate, authorize('dinas'), ctrl.getLaporanDistribusi);
router.get('/kelangkaan', authenticate, authorize('dinas'), ctrl.getAllKelangkaan);
router.post('/kelangkaan', authenticate, authorize('ketua_tani'), handleUpload('foto'), ctrl.createLaporanKelangkaan);
module.exports = router;
