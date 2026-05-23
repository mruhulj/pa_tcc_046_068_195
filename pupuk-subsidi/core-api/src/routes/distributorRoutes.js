const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/distributorController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

router.get('/', authenticate, authorize('dinas'), ctrl.getAll);
router.post('/', authenticate, authorize('dinas'), ctrl.create);
router.put('/:id', authenticate, authorize('dinas'), ctrl.update);

module.exports = router;
