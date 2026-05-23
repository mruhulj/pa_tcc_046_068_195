const db = require('../config/database');
const logger = require('../utils/logger');

const getAll = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT d.*, w.nama AS wilayah_nama
      FROM distributor d
      LEFT JOIN wilayah w ON d.wilayah_id = w.id
      ORDER BY d.nama ASC
    `);
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    logger.error('Get distributor error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const create = async (req, res) => {
  try {
    const { nama, alamat, telepon, wilayah_id, user_id } = req.body;
    if (!nama || !wilayah_id) {
      return res.status(400).json({ success: false, message: 'Nama dan wilayah_id wajib diisi' });
    }

    const [result] = await db.execute(
      'INSERT INTO distributor (nama, alamat, telepon, wilayah_id, user_id) VALUES (?, ?, ?, ?, ?)',
      [nama, alamat || null, telepon || null, wilayah_id, user_id || null]
    );

    return res.status(201).json({
      success: true,
      message: 'Distributor berhasil ditambahkan',
      data: { id: result.insertId, nama, wilayah_id }
    });
  } catch (err) {
    logger.error('Create distributor error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, alamat, telepon, status } = req.body;

    const [existing] = await db.execute('SELECT * FROM distributor WHERE id = ?', [id]);
    if (!existing.length) {
      return res.status(404).json({ success: false, message: 'Distributor tidak ditemukan' });
    }

    await db.execute(
      'UPDATE distributor SET nama = ?, alamat = ?, telepon = ?, status = ? WHERE id = ?',
      [nama || existing[0].nama, alamat || existing[0].alamat, telepon || existing[0].telepon, status || existing[0].status, id]
    );

    return res.status(200).json({ success: true, message: 'Distributor berhasil diupdate' });
  } catch (err) {
    logger.error('Update distributor error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getAll, create, update };
