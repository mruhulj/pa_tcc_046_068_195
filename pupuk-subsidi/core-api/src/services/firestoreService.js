const { Firestore } = require('@google-cloud/firestore');
const db = require('../config/firestore');
const logger = require('../utils/logger');

const addAuditLog = async (user, aksi, entityType, entityId, detail) => {
  try {
    await db.collection('log_audit').add({
      user_id: String(user.user_id),
      user_nama: user.nama,
      role: user.role,
      aksi, entity_type: entityType,
      entity_id: entityId, detail,
      created_at: Firestore.Timestamp.now()
    });
  } catch (err) { logger.error('Audit log error', { error: err.message }); }
};

const addNotifikasi = async (targetUserId, targetRole, judul, pesan, tipe, refId = null) => {
  try {
    await db.collection('notifikasi').add({
      target_user_id: String(targetUserId),
      target_role: targetRole,
      judul, pesan, tipe, is_read: false, ref_id: refId,
      created_at: Firestore.Timestamp.now()
    });
  } catch (err) { logger.error('Notifikasi error', { error: err.message }); }
};

const addLaporanKelangkaan = async (data) => {
  const docRef = await db.collection('laporan_kelangkaan').add({
    ...data, status: 'pending',
    created_at: Firestore.Timestamp.now(),
    updated_at: Firestore.Timestamp.now()
  });
  return docRef.id;
};

const addBuktiPenerimaan = async (data) => {
  const docRef = await db.collection('bukti_penerimaan').add({
    ...data, uploaded_at: Firestore.Timestamp.now()
  });
  return docRef.id;
};

const addUpdateDistribusi = async (data) => {
  const docRef = await db.collection('update_distribusi_lapangan').add({
    ...data, created_at: Firestore.Timestamp.now()
  });
  return docRef.id;
};

const getNotifikasiByUser = async (userId) => {
  try {
    const snapshot = await db.collection('notifikasi')
      .where('target_user_id', '==', String(userId)).limit(20).get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (err) { logger.error('Get notifikasi error', { error: err.message }); return []; }
};

const getLaporanKelangkaan = async (status = null) => {
  try {
    let query = db.collection('laporan_kelangkaan');
    if (status) query = query.where('status', '==', status);
    const snapshot = await query.limit(50).get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (err) { logger.error('Get laporan error', { error: err.message }); return []; }
};

module.exports = { addAuditLog, addNotifikasi, addLaporanKelangkaan, addBuktiPenerimaan, addUpdateDistribusi, getNotifikasiByUser, getLaporanKelangkaan };
