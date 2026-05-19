class UserModel {
  final int id;
  final String nama;
  final String email;
  final String role;
  final int? wilayahId;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.wilayahId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        nama: json['nama'],
        email: json['email'],
        role: json['role'],
        wilayahId: json['wilayah_id'],
      );
}

class DistribusiModel {
  final int id;
  final String? distributorNama;
  final String? kelompokTaniNama;
  final String? jenisPupuk;
  final double jumlahKg;
  final String? tanggalKirim;
  final String status;
  final String? catatan;

  DistribusiModel({
    required this.id,
    this.distributorNama,
    this.kelompokTaniNama,
    this.jenisPupuk,
    required this.jumlahKg,
    this.tanggalKirim,
    required this.status,
    this.catatan,
  });

  factory DistribusiModel.fromJson(Map<String, dynamic> json) => DistribusiModel(
        id: json['id'],
        distributorNama: json['distributor_nama'],
        kelompokTaniNama: json['kelompok_tani_nama'],
        jenisPupuk: json['jenis_pupuk'],
        jumlahKg: double.tryParse(json['jumlah_kg'].toString()) ?? 0,
        tanggalKirim: json['tanggal_kirim'],
        status: json['status'] ?? 'dikirim',
        catatan: json['catatan'],
      );
}

class PenerimaanModel {
  final int id;
  final String? kelompokNama;
  final String? jenisPupuk;
  final double jumlahDiterima;
  final double? jumlahDikirim;
  final String? tanggalTerima;
  final String statusVerifikasi;
  final String? fotoUrl;

  PenerimaanModel({
    required this.id,
    this.kelompokNama,
    this.jenisPupuk,
    required this.jumlahDiterima,
    this.jumlahDikirim,
    this.tanggalTerima,
    required this.statusVerifikasi,
    this.fotoUrl,
  });

  factory PenerimaanModel.fromJson(Map<String, dynamic> json) => PenerimaanModel(
        id: json['id'],
        kelompokNama: json['kelompok_nama'],
        jenisPupuk: json['jenis_pupuk'],
        jumlahDiterima: double.tryParse(json['jumlah_diterima'].toString()) ?? 0,
        jumlahDikirim: json['jumlah_dikirim'] != null
            ? double.tryParse(json['jumlah_dikirim'].toString())
            : null,
        tanggalTerima: json['tanggal_terima'],
        statusVerifikasi: json['status_verifikasi'] ?? 'pending',
        fotoUrl: json['foto_url'],
      );
}

class NotifikasiModel {
  final String id;
  final String judul;
  final String pesan;
  final String tipe;
  final bool isRead;
  final dynamic createdAt;

  NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    required this.isRead,
    this.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) => NotifikasiModel(
        id: json['id'],
        judul: json['judul'] ?? '',
        pesan: json['pesan'] ?? '',
        tipe: json['tipe'] ?? 'info',
        isRead: json['is_read'] ?? false,
        createdAt: json['created_at'],
      );
}
