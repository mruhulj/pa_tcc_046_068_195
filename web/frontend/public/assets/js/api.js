// Ganti dengan URL Cloud Run kalian setelah deploy
const AUTH_URL = 'https://auth-service-12842121571.asia-southeast2.run.app/api/v1';
const CORE_URL = 'https://core-api-12842121571.asia-southeast2.run.app/api/v1';

const getToken = () => localStorage.getItem('token');
const getUser = () => JSON.parse(localStorage.getItem('user') || '{}');

const apiFetch = async (baseUrl, path, method = 'GET', body = null, isFormData = false) => {
  const headers = { Authorization: `Bearer ${getToken()}` };
  if (!isFormData) headers['Content-Type'] = 'application/json';

  const opts = { method, headers };
  if (body) opts.body = isFormData ? body : JSON.stringify(body);

  const res = await fetch(`${baseUrl}${path}`, opts);
  const data = await res.json();

  if (res.status === 401) {
    localStorage.clear();
    window.location.href = '/login.html';
    return;
  }
  return data;
};

const auth = {
  login: (email, password) =>
    fetch(`${AUTH_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    }).then(r => r.json()),

  me: () => apiFetch(AUTH_URL, '/auth/me')
};

const api = {
  // Wilayah
  getWilayah: () => apiFetch(CORE_URL, '/wilayah'),

  // Kuota
  getKuota: (params = '') => apiFetch(CORE_URL, `/kuota${params}`),
  createKuota: (data) => apiFetch(CORE_URL, '/kuota', 'POST', data),
  updateKuota: (id, data) => apiFetch(CORE_URL, `/kuota/${id}`, 'PUT', data),

  // Distributor
  getDistributor: () => apiFetch(CORE_URL, '/distributor'),
  createDistributor: (data) => apiFetch(CORE_URL, '/distributor', 'POST', data),

  // Kelompok Tani
  getKelompokTani: (params = '') => apiFetch(CORE_URL, `/kelompok-tani${params}`),
  createKelompokTani: (data) => apiFetch(CORE_URL, '/kelompok-tani', 'POST', data),

  // Alokasi
  getAlokasi: (params = '') => apiFetch(CORE_URL, `/alokasi${params}`),
  createAlokasi: (data) => apiFetch(CORE_URL, '/alokasi', 'POST', data),

  // Distribusi
  getDistribusi: (params = '') => apiFetch(CORE_URL, `/distribusi${params}`),
  createDistribusi: (data) => apiFetch(CORE_URL, '/distribusi', 'POST', data),
  updateStatusDistribusi: (id, data) => apiFetch(CORE_URL, `/distribusi/${id}/status`, 'PUT', data),

  // Penerimaan
  getPenerimaan: (params = '') => apiFetch(CORE_URL, `/penerimaan${params}`),
  verifikasiPenerimaan: (id, data) => apiFetch(CORE_URL, `/penerimaan/${id}/verifikasi`, 'PUT', data),

  // Laporan
  getLaporanDistribusi: (params = '') => apiFetch(CORE_URL, `/laporan/distribusi${params}`),
  getLaporanKelangkaan: (params = '') => apiFetch(CORE_URL, `/laporan/kelangkaan${params}`),

  // Notifikasi
  getNotifikasi: () => apiFetch(CORE_URL, '/notifikasi')
};

// Guard: redirect ke login jika belum auth
const requireAuth = () => {
  if (!getToken()) window.location.href = '/login.html';
};

// Format tanggal Indonesia
const formatDate = (dateStr) => {
  if (!dateStr) return '-';
  return new Date(dateStr).toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' });
};

// Format angka dengan titik ribuan
const formatNumber = (num) => {
  return parseFloat(num || 0).toLocaleString('id-ID');
};

// Badge status
const badgeStatus = (status) => {
  const map = {
    'dikirim': 'bg-blue-100 text-blue-700',
    'diterima': 'bg-green-100 text-green-700',
    'bermasalah': 'bg-red-100 text-red-700',
    'pending': 'bg-yellow-100 text-yellow-700',
    'disetujui': 'bg-green-100 text-green-700',
    'ditolak': 'bg-red-100 text-red-700',
    'diverifikasi': 'bg-green-100 text-green-700',
    'aktif': 'bg-green-100 text-green-700',
    'nonaktif': 'bg-gray-100 text-gray-700',
  };
  return map[status] || 'bg-gray-100 text-gray-700';
};

const showToast = (msg, type = 'success') => {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = msg;
  toast.className = `fixed bottom-4 right-4 px-5 py-3 rounded-xl text-white text-sm font-medium shadow-lg z-50 transition-all ${type === 'success' ? 'bg-green-500' : 'bg-red-500'}`;
  toast.classList.remove('hidden');
  setTimeout(() => toast.classList.add('hidden'), 3000);
};
