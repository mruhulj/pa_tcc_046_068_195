import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class LaporanKelangkaanScreen extends StatefulWidget {
  const LaporanKelangkaanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanKelangkaanScreen> createState() =>
      _LaporanKelangkaanScreenState();
}

class _LaporanKelangkaanScreenState extends State<LaporanKelangkaanScreen> {
  final _formKey = GlobalKey<FormState>();
  String _jenisPupuk = 'Urea';
  final _deskripsiController = TextEditingController();
  File? _foto;
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    final img = await ImagePicker().pickImage(source: source);
    if (img != null) {
      setState(() => _foto = File(img.path));
    }
  }

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final result = await ApiService.createLaporanKelangkaan(
      jenisPupuk: _jenisPupuk,
      deskripsi: _deskripsiController.text,
      foto: _foto,
    );
    setState(() => _loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mengirim laporan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kelangkaan'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gunakan form ini untuk melaporkan kelangkaan atau keterlambatan distribusi pupuk subsidi.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Jenis Pupuk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: ['Urea', 'NPK', 'SP36', 'ZA'].map((jenis) {
                  return ChoiceChip(
                    label: Text(jenis),
                    selected: _jenisPupuk == jenis,
                    selectedColor: Colors.green,
                    onSelected: (sel) {
                      if (sel) setState(() => _jenisPupuk = jenis);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),
              const Text(
                'Deskripsi Kelangkaan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Jelaskan kelangkaan atau keterlambatan pupuk...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              const Text(
                'Foto Pendukung (opsional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_foto != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_foto!, height: 200, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _foto = null),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text('Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading ? null : _submitLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Laporan',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Hanya file JPG, PNG, WEBP yang diizinkan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
