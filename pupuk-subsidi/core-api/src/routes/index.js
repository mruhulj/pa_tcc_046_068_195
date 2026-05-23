const express = require('express');
const router = express.Router();

router.use('/wilayah', require('./wilayahRoutes'));
router.use('/kuota', require('./kuotaRoutes'));
router.use('/distributor', require('./distributorRoutes'));
router.use('/kelompok-tani', require('./kelompokTaniRoutes'));
router.use('/alokasi', require('./alokasiRoutes'));
router.use('/distribusi', require('./distribusiRoutes'));
router.use('/penerimaan', require('./penerimaanRoutes'));
router.use('/laporan', require('./laporanRoutes'));
router.use('/notifikasi', require('./notifikasiRoutes'));

module.exports = router;
