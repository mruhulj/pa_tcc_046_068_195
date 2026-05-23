const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/alokasiController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

router.get('/', authenticate, ctrl.getAll);
router.post('/', authenticate, authorize('dinas'), ctrl.create);

module.exports = router;
