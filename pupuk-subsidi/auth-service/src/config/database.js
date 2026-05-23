const mysql = require('mysql2/promise');
const logger = require('../utils/logger');

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  socketPath: process.env.DB_HOST && process.env.DB_HOST.startsWith('/cloudsql')
    ? process.env.DB_HOST
    : undefined
});

// Test koneksi
pool.getConnection()
  .then(conn => {
    logger.info('Database MySQL terhubung');
    conn.release();
  })
  .catch(err => {
    logger.error('Gagal koneksi database', { error: err.message });
  });

module.exports = pool;
