const db = require('../config/database');
const { addLaporanKelangkaan, getLaporanKelangkaan, getNotifikasiByUser } = require('../services/firestoreService');
const { uploadToGCS } = require('../services/storageService');
const logger = require('../utils/logger');

const getLaporanDistribusi = async (req, res) => {
  try {
    const { periode_bulan, periode_tahun, wilayah_id } = req.query;

    let kuotaQuery = `
      SELECT SUM(total_kuota_kg) AS total_kuota, SUM(sisa_kuota_kg) AS sisa_kuota
      FROM kuota_wilayah WHERE 1=1
    `;
    const kuotaParams = [];
    if (periode_bulan) { kuotaQuery += ' AND periode_bulan = ?'; kuotaParams.push(periode_bulan); }
    if (periode_tahun) { kuotaQuery += ' AND periode_tahun = ?'; kuotaParams.push(periode_tahun); }
    if (wilayah_id) { kuotaQuery += ' AND wilayah_id = ?'; kuotaParams.push(wilayah_id); }

    const [kuotaData] = await db.execute(kuotaQuery, kuotaParams);

    // Total alokasi
    let alokasiQuery = `SELECT SUM(jumlah_kg) AS total_alokasi FROM alokasi WHERE status = 'disetujui'`;
    const alokasiParams = [];
    if (wilayah_id) {
      alokasiQuery += ' AND kelompok_id IN (SELECT id FROM kelompok_tani WHERE wilayah_id = ?)';
      alokasiParams.push(wilayah_id);
    }
    const [alokasiData] = await db.execute(alokasiQuery, alokasiParams);

    // Total distribusi & penerimaan
    const [distribusiData] = await db.execute(`
      SELECT
        COUNT(*) AS jumlah_distribusi,
        SUM(jumlah_kg) AS total_dikirim,
        SUM(CASE WHEN status = 'diterima' THEN jumlah_kg ELSE 0 END) AS total_diterima
      FROM distribusi
    `);

    const [penerimaanData] = await db.execute(`
      SELECT SUM(jumlah_diterima) AS total_diterima_aktual FROM penerimaan WHERE status_verifikasi = 'diverifikasi'
    `);

    // Detail per kelompok
    let detailQuery = `
      SELECT
        kt.nama AS kelompok_tani,
        COALESCE(SUM(a.jumlah_kg), 0) AS dialokasikan_kg,
        COALESCE(SUM(p.jumlah_diterima), 0) AS diterima_kg,
        MAX(p.status_verifikasi) AS status_verif
      FROM kelompok_tani kt
      LEFT JOIN alokasi a ON kt.id = a.kelompok_id
      LEFT JOIN distribusi dis ON a.id = dis.alokasi_id
      LEFT JOIN penerimaan p ON dis.id = p.distribusi_id
      WHERE 1=1
    `;
    const detailParams = [];
    if (wilayah_id) { detailQuery += ' AND kt.wilayah_id = ?'; detailParams.push(wilayah_id); }
    detailQuery += ' GROUP BY kt.id, kt.nama ORDER BY kt.nama';

    const [detail] = await db.execute(detailQuery, detailParams);

    // Laporan kelangkaan dari Firestore
    const kelangkaan = await getLaporanKelangkaan();

    const totalKuota = parseFloat(kuotaData[0]?.total_kuota || 0);
    const totalDikirim = parseFloat(distribusiData[0]?.total_dikirim || 0);
    const totalDiterima = parseFloat(penerimaanData[0]?.total_diterima_aktual || 0);

    return res.status(200).json({
      success: true,
      data: {
        periode: periode_bulan && periode_tahun ? `${periode_bulan}/${periode_tahun}` : 'Semua periode',
        total_kuota_kg: totalKuota,
        total_dialokasikan_kg: parseFloat(alokasiData[0]?.total_alokasi || 0),
        total_dikirim_kg: totalDikirim,
        total_diterima_kg: totalDiterima,
        selisih_kg: totalDikirim - totalDiterima,
        jumlah_distribusi: distribusiData[0]?.jumlah_distribusi || 0,
        laporan_kelangkaan: kelangkaan.length,
        detail
      }
    });
  } catch (err) {
    logger.error('Get laporan distribusi error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const createLaporanKelangkaan = async (req, res) => {
  try {
    const { jenis_pupuk, deskripsi } = req.body;
    if (!jenis_pupuk || !deskripsi) {
      return res.status(400).json({ success: false, message: 'jenis_pupuk dan deskripsi wajib diisi' });
    }

    // Ambil info kelompok tani
    const [kt] = await db.execute(
      'SELECT kt.*, w.nama AS wilayah_nama FROM kelompok_tani kt LEFT JOIN wilayah w ON kt.wilayah_id = w.id WHERE kt.user_id = ?',
      [req.user.user_id]
    );

    let foto_url = null;
    if (req.file) {
      foto_url = await uploadToGCS(req.file, 'laporan-kelangkaan', req.user.user_id);
    }

    const docId = await addLaporanKelangkaan({
      kelompok_id: kt[0]?.id || null,
      kelompok_nama: kt[0]?.nama || req.user.nama,
      wilayah: kt[0]?.wilayah_nama || '',
      jenis_pupuk,
      deskripsi,
      foto_url,
      reported_by: String(req.user.user_id)
    });

    return res.status(201).json({
      success: true,
      message: 'Laporan kelangkaan berhasil dikirim',
      data: { id: docId, status: 'pending', created_at: new Date().toISOString() }
    });
  } catch (err) {
    logger.error('Create laporan kelangkaan error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const getAllKelangkaan = async (req, res) => {
  try {
    const { status } = req.query;
    const data = await getLaporanKelangkaan(status || null);
    return res.status(200).json({ success: true, data });
  } catch (err) {
    logger.error('Get laporan kelangkaan error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const getNotifikasi = async (req, res) => {
  try {
    const data = await getNotifikasiByUser(req.user.user_id);
    return res.status(200).json({ success: true, data });
  } catch (err) {
    logger.error('Get notifikasi error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { getLaporanDistribusi, createLaporanKelangkaan, getAllKelangkaan, getNotifikasi };
