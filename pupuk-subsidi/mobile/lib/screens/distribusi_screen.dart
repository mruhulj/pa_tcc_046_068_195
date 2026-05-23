import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DistribusiScreen extends StatefulWidget {
  const DistribusiScreen({super.key});

  @override
  State<DistribusiScreen> createState() => _DistribusiScreenState();
}

class _DistribusiScreenState extends State<DistribusiScreen> {
  List<DistribusiModel> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDistribusi();
      setState(() => _data = data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'dikirim': return const Color(0xFF3b82f6);
      case 'diterima': return const Color(0xFF16a34a);
      case 'bermasalah': return const Color(0xFFdc2626);
      default: return const Color(0xFF6b7280);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'dikirim': return const Color(0xFFeff6ff);
      case 'diterima': return const Color(0xFFf0fdf4);
      case 'bermasalah': return const Color(0xFFfef2f2);
      default: return const Color(0xFFf3f4f6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf9fafb),
      appBar: AppBar(
        title: const Text('Status Distribusi'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.local_shipping_outlined, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('Belum ada data distribusi', style: TextStyle(color: Color(0xFF9ca3af))),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _data.length,
                    itemBuilder: (ctx, i) {
                      final d = _data[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(d.kelompokTaniNama ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1f2937))),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _statusBg(d.status), borderRadius: BorderRadius.circular(20)),
                                    child: Text(d.status, style: TextStyle(color: _statusColor(d.status), fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF9ca3af)),
                                const SizedBox(width: 6),
                                Text('${d.jenisPupuk ?? '-'} · ${d.jumlahKg.toStringAsFixed(0)} kg',
                                  style: const TextStyle(color: Color(0xFF6b7280), fontSize: 13)),
                              ]),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.local_shipping_outlined, size: 14, color: Color(0xFF9ca3af)),
                                const SizedBox(width: 6),
                                Text(d.distributorNama ?? '-', style: const TextStyle(color: Color(0xFF6b7280), fontSize: 13)),
                              ]),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9ca3af)),
                                const SizedBox(width: 6),
                                Text(d.tanggalKirim ?? '-', style: const TextStyle(color: Color(0xFF6b7280), fontSize: 13)),
                              ]),
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
