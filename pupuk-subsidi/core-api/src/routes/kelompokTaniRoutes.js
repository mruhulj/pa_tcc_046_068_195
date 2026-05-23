const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/kelompokTaniController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

router.get('/', authenticate, authorize('dinas', 'distributor'), ctrl.getAll);
router.get('/:id', authenticate, ctrl.getById);
router.post('/', authenticate, authorize('dinas'), ctrl.create);
router.put('/:id', authenticate, authorize('dinas'), ctrl.update);

module.exports = router;
