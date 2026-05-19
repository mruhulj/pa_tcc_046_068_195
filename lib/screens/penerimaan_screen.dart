import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class PenerimaanScreen extends StatefulWidget {
  const PenerimaanScreen({Key? key}) : super(key: key);

  @override
  State<PenerimaanScreen> createState() => _PenerimaanScreenState();
}

class _PenerimaanScreenState extends State<PenerimaanScreen> {
  List<DistribusiModel> _distribusi = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await ApiService.getDistribusi(status: 'dikirim');
    setState(() {
      _distribusi = data;
      _loading = false;
    });
  }

  void _showKonfirmasiDialog(DistribusiModel dis) {
    final jumlahController = TextEditingController();
    final catatanController = TextEditingController();
    File? foto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalCtx) => StatefulBuilder(
        builder: (statefulCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(statefulCtx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Konfirmasi Penerimaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(statefulCtx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${dis.jenisPupuk} · ${dis.jumlahKg} kg dikirim',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Diterima (kg)',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan jumlah actual',
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: catatanController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: Ada selisih 20kg',
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Foto Bukti',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                          );
                          if (img != null) {
                            setModalState(() => foto = File(img.path));
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (img != null) {
                            setModalState(() => foto = File(img.path));
                          }
                        },
                        icon: const Icon(Icons.photo),
                        label: const Text('Galeri'),
                      ),
                    ),
                  ],
                ),
                if (foto != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(foto!, height: 150, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (jumlahController.text.isEmpty) {
                      ScaffoldMessenger.of(statefulCtx).showSnackBar(
                        const SnackBar(
                          content: Text('Jumlah diterima wajib diisi'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(statefulCtx); // Pop modal
                    
                    if (!mounted) return;
                    _showLoadingDialog(); // Uses parent context
                    
                    try {
                      final double jumlah = double.parse(jumlahController.text.replaceAll(',', '.'));
                      final result = await ApiService.createPenerimaan(
                        distribusiId: dis.id!,
                        jumlahDiterima: jumlah,
                        tanggalTerima: DateTime.now().toIso8601String().split('T')[0],
                        catatan: catatanController.text.isEmpty
                            ? null
                            : catatanController.text,
                        foto: foto,
                      );
                      
                      if (!mounted) return;
                      Navigator.pop(context); // Pop loading dialog using parent context
                      
                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Penerimaan berhasil dikonfirmasi'),
                          ),
                        );
                        _loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Gagal menyimpan'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.pop(context); // Pop loading dialog using parent context
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Terjadi kesalahan: $e'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text(
                    'Konfirmasi Penerimaan',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Penerimaan'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _distribusi.isEmpty
          ? const Center(
              child: Text('Belum ada distribusi yang perlu dikonfirmasi'),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _distribusi.length,
                itemBuilder: (ctx, i) {
                  final dis = _distribusi[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      title: Text(
                        dis.kelompokTaniNama ?? 'Kelompok Tani',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text('${dis.jenisPupuk} · ${dis.jumlahKg} kg'),
                          Text(
                            'Pengirim: ${dis.distributorNama ?? '-'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Tgl Kirim: ${dis.tanggalKirim ?? '-'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _showKonfirmasiDialog(dis),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Konfirmasi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
