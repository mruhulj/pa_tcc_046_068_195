const db = require('../config/database');
const { addAuditLog, addNotifikasi, addUpdateDistribusi } = require('../services/firestoreService');
const logger = require('../utils/logger');

const getAll = async (req, res) => {
  try {
    const { status, kelompok_id, distributor_id } = req.query;
    let query = `
      SELECT dis.*,
        d.nama AS distributor_nama,
        kt.nama AS kelompok_tani_nama,
        a.jenis_pupuk
      FROM distribusi dis
      LEFT JOIN distributor d ON dis.distributor_id = d.id
      LEFT JOIN kelompok_tani kt ON dis.kelompok_id = kt.id
      LEFT JOIN alokasi a ON dis.alokasi_id = a.id
      WHERE 1=1
    `;
    const params = [];

    if (req.user.role === 'distributor') {
      query += ' AND dis.distributor_id = (SELECT id FROM distributor WHERE user_id = ? LIMIT 1)';
      params.push(req.user.user_id);
    }
    if (req.user.role === 'ketua_tani') {
      query += ' AND dis.kelompok_id = (SELECT id FROM kelompok_tani WHERE user_id = ? LIMIT 1)';
      params.push(req.user.user_id);
    }
    if (status) { query += ' AND dis.status = ?'; params.push(status); }
    if (kelompok_id) { query += ' AND dis.kelompok_id = ?'; params.push(kelompok_id); }
    if (distributor_id) { query += ' AND dis.distributor_id = ?'; params.push(distributor_id); }
    query += ' ORDER BY dis.created_at DESC';

    const [rows] = await db.execute(query, params);
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    logger.error('Get distribusi error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const create = async (req, res) => {
  try {
    const { alokasi_id, tanggal_kirim, jumlah_kg, catatan } = req.body;
    if (!alokasi_id || !jumlah_kg) {
      return res.status(400).json({ success: false, message: 'alokasi_id dan jumlah_kg wajib diisi' });
    }

    const [alokasi] = await db.execute(
      'SELECT a.*, d.user_id AS dist_user_id, kt.user_id AS tani_user_id FROM alokasi a LEFT JOIN distributor d ON a.distributor_id = d.id LEFT JOIN kelompok_tani kt ON a.kelompok_id = kt.id WHERE a.id = ?',
      [alokasi_id]
    );
    if (!alokasi.length) return res.status(404).json({ success: false, message: 'Alokasi tidak ditemukan' });

    const al = alokasi[0];
    const [result] = await db.execute(
      'INSERT INTO distribusi (alokasi_id, distributor_id, kelompok_id, tanggal_kirim, jumlah_kg, catatan) VALUES (?, ?, ?, ?, ?, ?)',
      [alokasi_id, al.distributor_id, al.kelompok_id, tanggal_kirim || new Date().toISOString().split('T')[0], jumlah_kg, catatan || null]
    );

    // Notifikasi ke ketua tani
    if (al.tani_user_id) {
      await addNotifikasi(al.tani_user_id, 'ketua_tani',
        'Pupuk Sedang Dikirim',
        `${al.jenis_pupuk} ${jumlah_kg}kg sedang dalam perjalanan ke kelompok Anda`,
        'distribusi', result.insertId);
    }

    await addAuditLog(req.user, 'CREATE_DISTRIBUSI', 'distribusi', result.insertId,
      `Distribusi ${jumlah_kg}kg alokasi ${alokasi_id}`);

    return res.status(201).json({
      success: true,
      message: 'Data distribusi berhasil dicatat',
      data: { id: result.insertId, status: 'dikirim', tanggal_kirim }
    });
  } catch (err) {
    logger.error('Create distribusi error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const updateStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, catatan } = req.body;

    const validStatus = ['dikirim', 'diterima', 'bermasalah'];
    if (!status || !validStatus.includes(status)) {
      return res.status(400).json({ success: false, message: 'Status tidak valid' });
    }

    const [existing] = await db.execute('SELECT * FROM distribusi WHERE id = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Distribusi tidak ditemukan' });

    await db.execute('UPDATE distribusi SET status = ?, catatan = ? WHERE id = ?', [status, catatan || existing[0].catatan, id]);

    // Log ke Firestore
    await addUpdateDistribusi({
      distribusi_id: parseInt(id),
      distributor_id: existing[0].distributor_id,
      status_update: status,
      catatan: catatan || ''
    });

    await addAuditLog(req.user, 'UPDATE_DISTRIBUSI_STATUS', 'distribusi', id, `Update status ke ${status}`);

    return res.status(200).json({ success: true, message: 'Status distribusi berhasil diupdate', data: { id: parseInt(id), status } });
  } catch (err) {
    logger.error('Update distribusi status error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getAll, create, updateStatus };
