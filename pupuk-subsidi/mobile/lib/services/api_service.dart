import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/models.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers({bool isMultipart = false}) async {
    final token = await getToken();
    final headers = <String, String>{
      'Authorization': 'Bearer ${token ?? ''}',
    };
    if (!isMultipart) headers['Content-Type'] = 'application/json';
    return headers;
  }

  // AUTH
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.authUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.authUrl}/auth/me'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  // DISTRIBUSI
  static Future<List<DistribusiModel>> getDistribusi({String? status}) async {
    var url = '${ApiConfig.coreUrl}/distribusi?';
    if (status != null) url += 'status=$status';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((e) => DistribusiModel.fromJson(e)).toList();
    }
    return [];
  }

  // PENERIMAAN
  static Future<List<PenerimaanModel>> getPenerimaan({String? status}) async {
    var url = '${ApiConfig.coreUrl}/penerimaan?';
    if (status != null) url += 'status_verifikasi=$status';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((e) => PenerimaanModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> createPenerimaan({
    required int distribusiId,
    required double jumlahDiterima,
    required String tanggalTerima,
    String? catatan,
    File? foto,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.coreUrl}/penerimaan'),
    );
    request.headers['Authorization'] = 'Bearer ${token ?? ''}';
    request.fields['distribusi_id'] = distribusiId.toString();
    request.fields['jumlah_diterima'] = jumlahDiterima.toString();
    request.fields['tanggal_terima'] = tanggalTerima;
    if (catatan != null) request.fields['catatan'] = catatan;
    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  // LAPORAN KELANGKAAN
  static Future<Map<String, dynamic>> createLaporanKelangkaan({
    required String jenisPupuk,
    required String deskripsi,
    File? foto,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.coreUrl}/laporan/kelangkaan'),
    );
    request.headers['Authorization'] = 'Bearer ${token ?? ''}';
    request.fields['jenis_pupuk'] = jenisPupuk;
    request.fields['deskripsi'] = deskripsi;
    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body);
  }

  // NOTIFIKASI
  static Future<List<NotifikasiModel>> getNotifikasi() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.coreUrl}/notifikasi'),
      headers: await _headers(),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return (data['data'] as List).map((e) => NotifikasiModel.fromJson(e)).toList();
    }
    return [];
  }
}
