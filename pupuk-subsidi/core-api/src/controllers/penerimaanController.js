const db = require('../config/database');
const { addAuditLog, addNotifikasi, addBuktiPenerimaan } = require('../services/firestoreService');
const { uploadToGCS } = require('../services/storageService');
const logger = require('../utils/logger');

const getAll = async (req, res) => {
  try {
    const { status_verifikasi, kelompok_id } = req.query;
    let query = `
      SELECT p.*,
        kt.nama AS kelompok_nama,
        dis.jumlah_kg AS jumlah_dikirim,
        a.jenis_pupuk,
        u.nama AS verified_by_nama
      FROM penerimaan p
      LEFT JOIN kelompok_tani kt ON p.kelompok_id = kt.id
      LEFT JOIN distribusi dis ON p.distribusi_id = dis.id
      LEFT JOIN alokasi a ON dis.alokasi_id = a.id
      LEFT JOIN users u ON p.verified_by = u.id
      WHERE 1=1
    `;
    const params = [];

    if (req.user.role === 'ketua_tani') {
      query += ' AND p.kelompok_id = (SELECT id FROM kelompok_tani WHERE user_id = ? LIMIT 1)';
      params.push(req.user.user_id);
    }
    if (status_verifikasi) { query += ' AND p.status_verifikasi = ?'; params.push(status_verifikasi); }
    if (kelompok_id) { query += ' AND p.kelompok_id = ?'; params.push(kelompok_id); }
    query += ' ORDER BY p.created_at DESC';

    const [rows] = await db.execute(query, params);
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    logger.error('Get penerimaan error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const create = async (req, res) => {
  try {
    const { distribusi_id, jumlah_diterima, tanggal_terima, catatan } = req.body;
    if (!distribusi_id || !jumlah_diterima) {
      return res.status(400).json({ success: false, message: 'distribusi_id dan jumlah_diterima wajib diisi' });
    }

    const [distribusi] = await db.execute(
      'SELECT dis.*, kt.id AS kt_id FROM distribusi dis LEFT JOIN kelompok_tani kt ON dis.kelompok_id = kt.id WHERE dis.id = ?',
      [distribusi_id]
    );
    if (!distribusi.length) return res.status(404).json({ success: false, message: 'Data distribusi tidak ditemukan' });

    // Upload foto jika ada
    let foto_url = null;
    if (req.file) {
      foto_url = await uploadToGCS(req.file, 'bukti-penerimaan', distribusi_id);
    }

    const [result] = await db.execute(
      'INSERT INTO penerimaan (distribusi_id, kelompok_id, jumlah_diterima, tanggal_terima, foto_url, catatan) VALUES (?, ?, ?, ?, ?, ?)',
      [distribusi_id, distribusi[0].kelompok_id, jumlah_diterima, tanggal_terima || new Date().toISOString().split('T')[0], foto_url, catatan || null]
    );

    // Update status distribusi
    await db.execute("UPDATE distribusi SET status = 'diterima' WHERE id = ?", [distribusi_id]);

    // Simpan bukti ke Firestore
    if (foto_url) {
      await addBuktiPenerimaan({
        penerimaan_id: result.insertId,
        kelompok_id: distribusi[0].kelompok_id,
        foto_urls: [foto_url],
        uploaded_by: String(req.user.user_id)
      });
    }

    // Notifikasi ke dinas
    await addNotifikasi(0, 'dinas',
      'Penerimaan Perlu Diverifikasi',
      `Kelompok tani telah konfirmasi penerimaan ${jumlah_diterima}kg pupuk`,
      'verifikasi', result.insertId);

    await addAuditLog(req.user, 'CREATE_PENERIMAAN', 'penerimaan', result.insertId,
      `Konfirmasi penerimaan ${jumlah_diterima}kg distribusi ${distribusi_id}`);

    return res.status(201).json({
      success: true,
      message: 'Penerimaan berhasil dicatat',
      data: { id: result.insertId, jumlah_diterima, foto_url, status_verifikasi: 'pending' }
    });
  } catch (err) {
    logger.error('Create penerimaan error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const verifikasi = async (req, res) => {
  try {
    const { id } = req.params;
    const { status_verifikasi, catatan } = req.body;

    const validStatus = ['diverifikasi', 'ditolak'];
    if (!status_verifikasi || !validStatus.includes(status_verifikasi)) {
      return res.status(400).json({ success: false, message: 'status_verifikasi harus diverifikasi atau ditolak' });
    }

    const [existing] = await db.execute('SELECT * FROM penerimaan WHERE id = ?', [id]);
    if (!existing.length) return res.status(404).json({ success: false, message: 'Penerimaan tidak ditemukan' });

    await db.execute(
      'UPDATE penerimaan SET status_verifikasi = ?, verified_by = ?, catatan = ? WHERE id = ?',
      [status_verifikasi, req.user.user_id, catatan || existing[0].catatan, id]
    );

    // Notifikasi ke ketua tani
    const [kt] = await db.execute(
      'SELECT user_id FROM kelompok_tani WHERE id = ?', [existing[0].kelompok_id]
    );
    if (kt.length && kt[0].user_id) {
      await addNotifikasi(kt[0].user_id, 'ketua_tani',
        'Status Penerimaan Diupdate',
        `Penerimaan pupuk Anda telah ${status_verifikasi} oleh Dinas`,
        'verifikasi', parseInt(id));
    }

    await addAuditLog(req.user, 'VERIFIKASI_PENERIMAAN', 'penerimaan', id,
      `Verifikasi penerimaan ${id} -> ${status_verifikasi}`);

    return res.status(200).json({
      success: true,
      message: 'Penerimaan berhasil diverifikasi',
      data: { id: parseInt(id), status_verifikasi, verified_by: req.user.nama }
    });
  } catch (err) {
    logger.error('Verifikasi penerimaan error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getAll, create, verifikasi };
