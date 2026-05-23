const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/laporanController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, ctrl.getNotifikasi);

module.exports = router;
