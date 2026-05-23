const db = require('../config/database');
const { addAuditLog, addNotifikasi } = require('../services/firestoreService');
const logger = require('../utils/logger');

const getAll = async (req, res) => {
  try {
    const { status, distributor_id, kelompok_id } = req.query;
    let query = `
      SELECT a.*,
        d.nama AS distributor_nama,
        kt.nama AS kelompok_tani_nama,
        w.nama AS wilayah_nama
      FROM alokasi a
      LEFT JOIN distributor d ON a.distributor_id = d.id
      LEFT JOIN kelompok_tani kt ON a.kelompok_id = kt.id
      LEFT JOIN wilayah w ON kt.wilayah_id = w.id
      WHERE 1=1
    `;
    const params = [];

    // Filter by role
    if (req.user.role === 'distributor') {
      query += ' AND a.distributor_id = (SELECT id FROM distributor WHERE user_id = ? LIMIT 1)';
      params.push(req.user.user_id);
    }
    if (req.user.role === 'ketua_tani') {
      query += ' AND a.kelompok_id = (SELECT id FROM kelompok_tani WHERE user_id = ? LIMIT 1)';
      params.push(req.user.user_id);
    }

    if (status) { query += ' AND a.status = ?'; params.push(status); }
    if (distributor_id) { query += ' AND a.distributor_id = ?'; params.push(distributor_id); }
    if (kelompok_id) { query += ' AND a.kelompok_id = ?'; params.push(kelompok_id); }
    query += ' ORDER BY a.created_at DESC';

    const [rows] = await db.execute(query, params);
    return res.status(200).json({ success: true, data: rows });
  } catch (err) {
    logger.error('Get alokasi error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const create = async (req, res) => {
  try {
    const { kuota_id, distributor_id, kelompok_id, jenis_pupuk, jumlah_kg, tanggal_alokasi } = req.body;

    if (!kuota_id || !distributor_id || !kelompok_id || !jenis_pupuk || !jumlah_kg) {
      return res.status(400).json({ success: false, message: 'Semua field wajib diisi' });
    }

    // Cek sisa kuota
    const [kuota] = await db.execute('SELECT * FROM kuota_wilayah WHERE id = ?', [kuota_id]);
    if (!kuota.length) return res.status(404).json({ success: false, message: 'Kuota tidak ditemukan' });
    if (kuota[0].sisa_kuota_kg < jumlah_kg) {
      return res.status(400).json({
        success: false,
        message: `Sisa kuota tidak mencukupi. Sisa: ${kuota[0].sisa_kuota_kg}kg`
      });
    }

    // Buat alokasi & kurangi sisa kuota (transaksi)
    const conn = await db.getConnection();
    try {
      await conn.beginTransaction();
      const [result] = await conn.execute(
        'INSERT INTO alokasi (kuota_id, distributor_id, kelompok_id, jenis_pupuk, jumlah_kg, status, tanggal_alokasi) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [kuota_id, distributor_id, kelompok_id, jenis_pupuk, jumlah_kg, 'disetujui', tanggal_alokasi || new Date().toISOString().split('T')[0]]
      );
      await conn.execute(
        'UPDATE kuota_wilayah SET sisa_kuota_kg = sisa_kuota_kg - ? WHERE id = ?',
        [jumlah_kg, kuota_id]
      );
      await conn.commit();

      // Notifikasi ke distributor
      const [dist] = await db.execute('SELECT user_id FROM distributor WHERE id = ?', [distributor_id]);
      if (dist.length && dist[0].user_id) {
        await addNotifikasi(dist[0].user_id, 'distributor',
          'Alokasi Pupuk Baru',
          `Anda mendapat alokasi ${jenis_pupuk} ${jumlah_kg}kg untuk didistribusikan`,
          'distribusi', result.insertId);
      }

      await addAuditLog(req.user, 'CREATE_ALOKASI', 'alokasi', result.insertId,
        `Alokasi ${jenis_pupuk} ${jumlah_kg}kg distributor ${distributor_id} ke kelompok ${kelompok_id}`);

      return res.status(201).json({
        success: true,
        message: 'Alokasi berhasil dibuat',
        data: { id: result.insertId, jumlah_kg, status: 'disetujui' }
      });
    } catch (e) {
      await conn.rollback();
      throw e;
    } finally {
      conn.release();
    }
  } catch (err) {
    logger.error('Create alokasi error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getAll, create };
