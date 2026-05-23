const db = require('../config/database');
const { addAuditLog } = require('../services/firestoreService');
const logger = require('../utils/logger');

const getAll = async (req, res) => {
  try {
    const { wilayah_id, periode_bulan, periode_tahun } = req.query;
    let query = `
      SELECT k.*, w.nama AS wilayah_nama,
        u.nama AS created_by_nama
      FROM kuota_wilayah k
      LEFT JOIN wilayah w ON k.wilayah_id = w.id
      LEFT JOIN users u ON k.created_by = u.id
      WHERE 1=1
    `;
    const params = [];
    if (wilayah_id) { query += ' AND k.wilayah_id = ?'; params.push(wilayah_id); }
    if (periode_bulan) { query += ' AND k.periode_bulan = ?'; params.push(periode_bulan); }
    if (periode_tahun) { query += ' AND k.periode_tahun = ?'; params.push(periode_tahun); }
    query += ' ORDER BY k.created_at DESC';

    const [rows] = await db.execute(query, params);
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    logger.error('Get kuota error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const create = async (req, res) => {
  try {
    const { wilayah_id, jenis_pupuk, periode_bulan, periode_tahun, total_kuota_kg } = req.body;

    if (!wilayah_id || !jenis_pupuk || !periode_bulan || !periode_tahun || !total_kuota_kg) {
      return res.status(400).json({ success: false, message: 'Semua field wajib diisi' });
    }

    const validPupuk = ['Urea', 'NPK', 'SP36', 'ZA'];
    if (!validPupuk.includes(jenis_pupuk)) {
      return res.status(400).json({ success: false, message: 'Jenis pupuk tidak valid' });
    }

    const [result] = await db.execute(
      `INSERT INTO kuota_wilayah (wilayah_id, jenis_pupuk, periode_bulan, periode_tahun, total_kuota_kg, sisa_kuota_kg, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [wilayah_id, jenis_pupuk, periode_bulan, periode_tahun, total_kuota_kg, total_kuota_kg, req.user.user_id]
    );

    await addAuditLog(req.user, 'CREATE_KUOTA', 'kuota_wilayah', result.insertId,
      `Buat kuota ${jenis_pupuk} ${total_kuota_kg}kg periode ${periode_bulan}/${periode_tahun}`);

    return res.status(201).json({
      success: true,
      message: 'Kuota berhasil dibuat',
      data: { id: result.insertId, wilayah_id, jenis_pupuk, total_kuota_kg, sisa_kuota_kg: total_kuota_kg }
    });
  } catch (err) {
    logger.error('Create kuota error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const update = async (req, res) => {
  try {
    const { id } = req.params;
    const { total_kuota_kg } = req.body;

    if (!total_kuota_kg) {
      return res.status(400).json({ success: false, message: 'total_kuota_kg wajib diisi' });
    }

    const [existing] = await db.execute('SELECT * FROM kuota_wilayah WHERE id = ?', [id]);
    if (!existing.length) {
      return res.status(404).json({ success: false, message: 'Kuota tidak ditemukan' });
    }

    const used = existing[0].total_kuota_kg - existing[0].sisa_kuota_kg;
    const newSisa = total_kuota_kg - used;

    if (newSisa < 0) {
      return res.status(400).json({ success: false, message: `Total kuota baru tidak boleh kurang dari yang sudah digunakan (${used}kg)` });
    }

    await db.execute(
      'UPDATE kuota_wilayah SET total_kuota_kg = ?, sisa_kuota_kg = ? WHERE id = ?',
      [total_kuota_kg, newSisa, id]
    );

    await addAuditLog(req.user, 'UPDATE_KUOTA', 'kuota_wilayah', id,
      `Update kuota dari ${existing[0].total_kuota_kg}kg ke ${total_kuota_kg}kg`);

    return res.status(200).json({
      success: true,
      message: 'Kuota berhasil diupdate',
      data: { id: parseInt(id), total_kuota_kg, sisa_kuota_kg: newSisa }
    });
  } catch (err) {
    logger.error('Update kuota error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getAll, create, update };
