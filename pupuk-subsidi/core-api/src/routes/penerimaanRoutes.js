const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/penerimaanController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { handleUpload } = require('../middleware/uploadMiddleware');

router.get('/', authenticate, ctrl.getAll);
router.post('/', authenticate, authorize('ketua_tani'), handleUpload('foto'), ctrl.create);
router.put('/:id/verifikasi', authenticate, authorize('dinas'), ctrl.verifikasi);
module.exports = router;
