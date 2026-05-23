const db = require('../config/database');
const logger = require('../utils/logger');

const getAll = async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM wilayah ORDER BY nama ASC');
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    logger.error('Get wilayah error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const create = async (req, res) => {
  try {
    const { nama, provinsi, kabupaten, kecamatan } = req.body;
    if (!nama) return res.status(400).json({ success: false, message: 'Nama wilayah wajib diisi' });

    const [result] = await db.execute(
      'INSERT INTO wilayah (nama, provinsi, kabupaten, kecamatan) VALUES (?, ?, ?, ?)',
      [nama, provinsi || null, kabupaten || null, kecamatan || null]
    );
    return res.status(201).json({
      success: true,
      message: 'Wilayah berhasil ditambahkan',
      data: { id: result.insertId, nama, provinsi, kabupaten, kecamatan }
    });
  } catch (err) {
    logger.error('Create wilayah error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getAll, create };
