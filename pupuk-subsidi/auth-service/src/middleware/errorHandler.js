const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  logger.error(err.message, { stack: err.stack, url: req.originalUrl, method: req.method });
  return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
};

module.exports = { errorHandler };
