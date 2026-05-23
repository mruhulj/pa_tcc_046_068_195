const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/distribusiController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

router.get('/', authenticate, ctrl.getAll);
router.post('/', authenticate, authorize('distributor', 'dinas'), ctrl.create);
router.put('/:id/status', authenticate, authorize('distributor', 'dinas'), ctrl.updateStatus);

module.exports = router;
