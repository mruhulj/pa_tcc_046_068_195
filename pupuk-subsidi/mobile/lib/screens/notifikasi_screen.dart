import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<NotifikasiModel> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getNotifikasi();
      setState(() => _data = data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  IconData _tipeIcon(String tipe) {
    switch (tipe) {
      case 'distribusi': return Icons.local_shipping_outlined;
      case 'verifikasi': return Icons.check_circle_outline;
      case 'kelangkaan': return Icons.warning_amber_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _tipeColor(String tipe) {
    switch (tipe) {
      case 'distribusi': return const Color(0xFF3b82f6);
      case 'verifikasi': return const Color(0xFF16a34a);
      case 'kelangkaan': return const Color(0xFFdc2626);
      default: return const Color(0xFF6b7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf9fafb),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('Tidak ada notifikasi', style: TextStyle(color: Color(0xFF9ca3af))),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _data.length,
                    itemBuilder: (ctx, i) {
                      final n = _data[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: n.isRead ? Colors.white : const Color(0xFFf0fdf4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: n.isRead ? const Color(0xFFf3f4f6) : const Color(0xFFbbf7d0)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: _tipeColor(n.tipe).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_tipeIcon(n.tipe), color: _tipeColor(n.tipe), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.judul, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1f2937))),
                                    const SizedBox(height: 3),
                                    Text(n.pesan, style: const TextStyle(color: Color(0xFF6b7280), fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF16a34a), shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
