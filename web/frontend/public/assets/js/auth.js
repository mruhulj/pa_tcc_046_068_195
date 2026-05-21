// Shared navbar untuk semua halaman dashboard
const renderNavbar = (activePage = '') => {
  const user = getUser();
  const roleLabel = { dinas: 'Dinas Pertanian', distributor: 'Distributor', ketua_tani: 'Ketua Kelompok Tani' };

  const navItems = [
    { href: '/pages/dashboard.html', icon: 'fa-chart-pie', label: 'Dashboard', key: 'dashboard' },
    { href: '/pages/kuota.html', icon: 'fa-box', label: 'Kuota', key: 'kuota', roles: ['dinas'] },
    { href: '/pages/distributor.html', icon: 'fa-truck', label: 'Distributor', key: 'distributor', roles: ['dinas'] },
    { href: '/pages/kelompok-tani.html', icon: 'fa-users', label: 'Kelompok Tani', key: 'kelompok', roles: ['dinas'] },
    { href: '/pages/alokasi.html', icon: 'fa-tasks', label: 'Alokasi', key: 'alokasi', roles: ['dinas'] },
    { href: '/pages/distribusi.html', icon: 'fa-shipping-fast', label: 'Distribusi', key: 'distribusi' },
    { href: '/pages/penerimaan.html', icon: 'fa-clipboard-check', label: 'Penerimaan', key: 'penerimaan' },
    { href: '/pages/laporan.html', icon: 'fa-file-alt', label: 'Laporan', key: 'laporan', roles: ['dinas'] },
  ];

  const filtered = navItems.filter(item => !item.roles || item.roles.includes(user.role));

  const links = filtered.map(item => `
    <a href="${item.href}"
      class="flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition-all
        ${activePage === item.key
          ? 'bg-green-700 text-white'
          : 'text-green-100 hover:bg-green-700/60 hover:text-white'}">
      <i class="fas ${item.icon} w-4 text-center"></i>
      <span>${item.label}</span>
    </a>
  `).join('');

  return `
    <aside class="fixed top-0 left-0 h-full w-60 bg-green-800 flex flex-col z-30">
      <div class="p-5 border-b border-green-700">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 bg-white rounded-xl flex items-center justify-center">
            <i class="fas fa-seedling text-green-700 text-lg"></i>
          </div>
          <div>
            <p class="text-white font-bold text-sm">SiPupuk</p>
            <p class="text-green-300 text-xs">Pupuk Subsidi</p>
          </div>
        </div>
      </div>

      <nav class="flex-1 p-4 space-y-1 overflow-y-auto">
        ${links}
      </nav>

      <div class="p-4 border-t border-green-700">
        <div class="flex items-center gap-3 mb-3">
          <div class="w-9 h-9 bg-green-600 rounded-xl flex items-center justify-center">
            <i class="fas fa-user text-white text-sm"></i>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-white text-xs font-semibold truncate">${user.nama || 'User'}</p>
            <p class="text-green-300 text-xs truncate">${roleLabel[user.role] || user.role}</p>
          </div>
        </div>
        <button onclick="logout()"
          class="w-full flex items-center justify-center gap-2 bg-green-700 hover:bg-red-600 text-white text-xs font-medium py-2 rounded-xl transition">
          <i class="fas fa-sign-out-alt"></i> Keluar
        </button>
      </div>
    </aside>

    <div class="ml-60 flex-1">
  `;
};

const logout = () => {
  localStorage.clear();
  window.location.href = '/login.html';
};
