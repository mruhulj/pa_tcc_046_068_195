import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class PenerimaanScreen extends StatefulWidget {
  const PenerimaanScreen({super.key});

  @override
  State<PenerimaanScreen> createState() => _PenerimaanScreenState();
}

class _PenerimaanScreenState extends State<PenerimaanScreen> {
  List<DistribusiModel> _distribusi = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDistribusi(status: 'dikirim');
      setState(() => _distribusi = data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _openForm(DistribusiModel dist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormPenerimaan(distribusi: dist, onSuccess: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf9fafb),
      appBar: AppBar(
        title: const Text('Konfirmasi Penerimaan'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _distribusi.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('Tidak ada distribusi yang perlu dikonfirmasi', style: TextStyle(color: Color(0xFF9ca3af)), textAlign: TextAlign.center),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _distribusi.length,
                    itemBuilder: (ctx, i) {
                      final d = _distribusi[i];
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
                              Text(d.kelompokTaniNama ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 6),
                              Text('${d.jenisPupuk ?? '-'} · ${d.jumlahKg.toStringAsFixed(0)} kg',
                                style: const TextStyle(color: Color(0xFF6b7280), fontSize: 13)),
                              Text('Pengirim: ${d.distributorNama ?? '-'}',
                                style: const TextStyle(color: Color(0xFF6b7280), fontSize: 13)),
                              Text('Tgl Kirim: ${d.tanggalKirim ?? '-'}',
                                style: const TextStyle(color: Color(0xFF6b7280), fontSize: 13)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openForm(d),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Konfirmasi Penerimaan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16a34a),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
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

class _FormPenerimaan extends StatefulWidget {
  final DistribusiModel distribusi;
  final VoidCallback onSuccess;
  const _FormPenerimaan({required this.distribusi, required this.onSuccess});

  @override
  State<_FormPenerimaan> createState() => _FormPenerimaanState();
}

class _FormPenerimaanState extends State<_FormPenerimaan> {
  final _jumlahCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  File? _foto;
  bool _loading = false;

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _pickGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _submit() async {
    final jumlah = double.tryParse(_jumlahCtrl.text);
    if (jumlah == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah diterima wajib diisi')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.createPenerimaan(
        distribusiId: widget.distribusi.id,
        jumlahDiterima: jumlah,
        tanggalTerima: DateTime.now().toIso8601String().split('T')[0],
        catatan: _catatanCtrl.text.isNotEmpty ? _catatanCtrl.text : null,
        foto: _foto,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penerimaan berhasil dikonfirmasi'), backgroundColor: Color(0xFF16a34a)));
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke server')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Konfirmasi Penerimaan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${widget.distribusi.jenisPupuk ?? '-'} · ${widget.distribusi.jumlahKg.toStringAsFixed(0)} kg dikirim',
              style: const TextStyle(color: Color(0xFF6b7280), fontSize: 13)),
            const SizedBox(height: 20),
            const Text('Jumlah Diterima (kg)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _jumlahCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masukkan jumlah actual',
                filled: true, fillColor: const Color(0xFFf9fafb),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Catatan (opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _catatanCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Contoh: Ada selisih 20kg',
                filled: true, fillColor: const Color(0xFFf9fafb),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Foto Bukti', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            if (_foto != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_foto!, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Kamera', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16a34a),
                      side: const BorderSide(color: Color(0xFF16a34a)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Galeri', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16a34a),
                      side: const BorderSide(color: Color(0xFF16a34a)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Konfirmasi Penerimaan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
