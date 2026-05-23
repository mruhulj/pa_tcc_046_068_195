import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'distribusi_screen.dart';
import 'penerimaan_screen.dart';
import 'laporan_kelangkaan_screen.dart';
import 'notifikasi_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _user = {};
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadNotifCount();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) setState(() => _user = jsonDecode(userStr));
  }

  Future<void> _loadNotifCount() async {
    try {
      final notifs = await ApiService.getNotifikasi();
      setState(() => _notifCount = notifs.where((n) => !n.isRead).length);
    } catch (_) {}
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final nama = _user['nama'] ?? 'User';
    final role = _user['role'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFf9fafb),
      appBar: AppBar(
        title: const Text('SiPupuk', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
              ),
              if (_notifCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Center(child: Text('$_notifCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF16a34a), Color(0xFF15803d)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selamat Datang,', style: TextStyle(color: Color(0xFFbbf7d0), fontSize: 12)),
                        Text(nama, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(role.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Menu Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
            const SizedBox(height: 14),
            // Menu Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _menuCard(
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF3b82f6),
                  bgColor: const Color(0xFFeff6ff),
                  label: 'Status Distribusi',
                  subtitle: 'Lihat pengiriman pupuk',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DistribusiScreen())),
                ),
                _menuCard(
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF16a34a),
                  bgColor: const Color(0xFFf0fdf4),
                  label: 'Konfirmasi Terima',
                  subtitle: 'Upload bukti penerimaan',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PenerimaanScreen())),
                ),
                _menuCard(
                  icon: Icons.warning_amber_outlined,
                  color: const Color(0xFFdc2626),
                  bgColor: const Color(0xFFfef2f2),
                  label: 'Lapor Kelangkaan',
                  subtitle: 'Laporkan masalah pupuk',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanKelangkaanScreen())),
                ),
                _menuCard(
                  icon: Icons.notifications_outlined,
                  color: const Color(0xFFd97706),
                  bgColor: const Color(0xFFfffbeb),
                  label: 'Notifikasi',
                  subtitle: 'Lihat pemberitahuan',
                  badge: _notifCount > 0 ? '$_notifCount' : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf0fdf4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFbbf7d0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF16a34a), size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF15803d), fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Gunakan aplikasi ini untuk konfirmasi penerimaan pupuk dan melaporkan kelangkaan.',
                          style: TextStyle(color: Color(0xFF166534), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1f2937))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF6b7280), fontSize: 11)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
