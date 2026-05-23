const db = require('../config/database');
const logger = require('../utils/logger');

const getAll = async (req, res) => {
  try {
    const { wilayah_id } = req.query;
    let query = `
      SELECT kt.*, w.nama AS wilayah_nama
      FROM kelompok_tani kt
      LEFT JOIN wilayah w ON kt.wilayah_id = w.id
      WHERE 1=1
    `;
    const params = [];
    if (wilayah_id) { query += ' AND kt.wilayah_id = ?'; params.push(wilayah_id); }
    query += ' ORDER BY kt.nama ASC';

    const [rows] = await db.execute(query, params);
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    logger.error('Get kelompok tani error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const getById = async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.execute(`
      SELECT kt.*, w.nama AS wilayah_nama
      FROM kelompok_tani kt
      LEFT JOIN wilayah w ON kt.wilayah_id = w.id
      WHERE kt.id = ?
    `, [id]);

    if (!rows.length) return res.status(404).json({ success: false, message: 'Kelompok tani tidak ditemukan' });
    return res.status(200).json({ success: true, data: rows[0] });
  } catch (err) {
    logger.error('Get kelompok tani by id error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const create = async (req, res) => {
  try {
    const { nama, ketua_nama, alamat, telepon, wilayah_id, jumlah_anggota, user_id } = req.body;
    if (!nama || !wilayah_id) {
      return res.status(400).json({ success: false, message: 'Nama dan wilayah_id wajib diisi' });
    }

    const [result] = await db.execute(
      'INSERT INTO kelompok_tani (nama, ketua_nama, alamat, telepon, wilayah_id, jumlah_anggota, user_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [nama, ketua_nama || null, alamat || null, telepon || null, wilayah_id, jumlah_anggota || 0, user_id || null]
    );

    return res.status(201).json({
      success: true,
      message: 'Kelompok tani berhasil ditambahkan',
      data: { id: result.insertId, nama, ketua_nama, wilayah_id }
    });
  } catch (err) {
    logger.error('Create kelompok tani error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const update = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, ketua_nama, alamat, telepon, jumlah_anggota, status } = req.body;

    const [existing] = await db.execute('SELECT * FROM kelompok_tani WHERE id = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Kelompok tani tidak ditemukan' });

    const e = existing[0];
    await db.execute(
      'UPDATE kelompok_tani SET nama=?, ketua_nama=?, alamat=?, telepon=?, jumlah_anggota=?, status=? WHERE id=?',
      [nama||e.nama, ketua_nama||e.ketua_nama, alamat||e.alamat, telepon||e.telepon, jumlah_anggota||e.jumlah_anggota, status||e.status, id]
    );

    return res.status(200).json({ success: true, message: 'Kelompok tani berhasil diupdate' });
  } catch (err) {
    logger.error('Update kelompok tani error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getAll, getById, create, update };
