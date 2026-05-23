import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class LaporanKelangkaanScreen extends StatefulWidget {
  const LaporanKelangkaanScreen({super.key});

  @override
  State<LaporanKelangkaanScreen> createState() => _LaporanKelangkaanScreenState();
}

class _LaporanKelangkaanScreenState extends State<LaporanKelangkaanScreen> {
  final _deskripsiCtrl = TextEditingController();
  String _jenisPupuk = 'Urea';
  File? _foto;
  bool _loading = false;
  bool _success = false;

  final List<String> _jenisPupukList = ['Urea', 'NPK', 'SP36', 'ZA'];

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _submit() async {
    if (_deskripsiCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi kelangkaan wajib diisi')));
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await ApiService.createLaporanKelangkaan(
        jenisPupuk: _jenisPupuk,
        deskripsi: _deskripsiCtrl.text.trim(),
        foto: _foto,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() => _success = true);
        _deskripsiCtrl.clear();
        _foto = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal mengirim laporan')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung ke server')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf9fafb),
      appBar: AppBar(title: const Text('Laporan Kelangkaan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFf0fdf4), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Color(0xFF16a34a), size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Laporan Terkirim!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
          const SizedBox(height: 8),
          const Text('Laporan kelangkaan pupuk Anda telah diterima dan akan segera ditindaklanjuti oleh Dinas Pertanian.',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6b7280), fontSize: 14)),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => setState(() => _success = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16a34a),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Buat Laporan Lain'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFfef2f2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFfecaca)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFdc2626), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Gunakan form ini untuk melaporkan kelangkaan atau keterlambatan distribusi pupuk subsidi.',
                  style: TextStyle(color: Color(0xFF991b1b), fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Jenis Pupuk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _jenisPupukList.map((p) => ChoiceChip(
            label: Text(p),
            selected: _jenisPupuk == p,
            onSelected: (_) => setState(() => _jenisPupuk = p),
            selectedColor: const Color(0xFF16a34a),
            labelStyle: TextStyle(
              color: _jenisPupuk == p ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: const Color(0xFFf3f4f6),
          )).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Deskripsi Kelangkaan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _deskripsiCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Jelaskan masalah kelangkaan pupuk yang terjadi...',
            hintStyle: const TextStyle(color: Color(0xFF9ca3af), fontSize: 13),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Foto Pendukung (opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_foto != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_foto!, height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _foto = null),
            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFdc2626)),
            label: const Text('Hapus foto', style: TextStyle(color: Color(0xFFdc2626), fontSize: 13)),
          ),
        ] else
          GestureDetector(
            onTap: _pickFoto,
            child: Container(
              height: 100, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFd1d5db), style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, color: Color(0xFF9ca3af), size: 28),
                  SizedBox(height: 6),
                  Text('Tap untuk ambil foto', style: TextStyle(color: Color(0xFF9ca3af), fontSize: 13)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(_loading ? 'Mengirim...' : 'Kirim Laporan',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFdc2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
