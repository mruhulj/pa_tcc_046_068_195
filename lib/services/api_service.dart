import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.authServiceUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.authServiceUrl}/auth/me'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // DISTRIBUSI
  static Future<List<DistribusiModel>> getDistribusi({String? status}) async {
    try {
      var url = '${ApiConfig.coreApiUrl}/distribusi?';
      if (status != null) url += 'status=$status';
      final res = await http.get(Uri.parse(url), headers: await _headers()).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => DistribusiModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // PENERIMAAN
  static Future<List<PenerimaanModel>> getPenerimaan({String? status}) async {
    try {
      var url = '${ApiConfig.coreApiUrl}/penerimaan?';
      if (status != null) url += 'status_verifikasi=$status';
      final res = await http.get(Uri.parse(url), headers: await _headers()).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => PenerimaanModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createPenerimaan({
    required int distribusiId,
    required double jumlahDiterima,
    required String tanggalTerima,
    String? catatan,
    File? foto,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.coreApiUrl}/penerimaan'),
      );
      request.headers['Authorization'] = 'Bearer ${token ?? ''}';
      request.fields['distribusi_id'] = distribusiId.toString();
      request.fields['jumlah_diterima'] = jumlahDiterima.toString();
      request.fields['tanggal_terima'] = tanggalTerima;
      if (catatan != null) request.fields['catatan'] = catatan;
      if (foto != null) {
        final ext = foto.path.split('.').last.toLowerCase();
        MediaType mediaType;
        if (ext == 'png') mediaType = MediaType('image', 'png');
        else if (ext == 'webp') mediaType = MediaType('image', 'webp');
        else mediaType = MediaType('image', 'jpeg');

        request.files.add(await http.MultipartFile.fromPath(
          'foto', 
          foto.path,
          contentType: mediaType,
        ));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamed);
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      } else {
        String errorMsg = 'Server Error ${res.statusCode}';
        try {
          final decoded = jsonDecode(res.body);
          if (decoded['message'] != null) errorMsg = decoded['message'];
        } catch (_) {}
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke backend gagal: $e'};
    }
  }

  // LAPORAN KELANGKAAN
  static Future<Map<String, dynamic>> createLaporanKelangkaan({
    required String jenisPupuk,
    required String deskripsi,
    File? foto,
  }) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.coreApiUrl}/laporan/kelangkaan'),
      );
      request.headers['Authorization'] = 'Bearer ${token ?? ''}';
      request.fields['jenis_pupuk'] = jenisPupuk;
      request.fields['deskripsi'] = deskripsi;
      if (foto != null) {
        final ext = foto.path.split('.').last.toLowerCase();
        MediaType mediaType;
        if (ext == 'png') mediaType = MediaType('image', 'png');
        else if (ext == 'webp') mediaType = MediaType('image', 'webp');
        else mediaType = MediaType('image', 'jpeg');

        request.files.add(await http.MultipartFile.fromPath(
          'foto', 
          foto.path,
          contentType: mediaType,
        ));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamed);
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      } else {
        String errorMsg = 'Server Error ${res.statusCode}';
        try {
          final decoded = jsonDecode(res.body);
          if (decoded['message'] != null) errorMsg = decoded['message'];
        } catch (_) {}
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi ke backend gagal: $e'};
    }
  }

  // NOTIFIKASI
  static Future<List<NotifikasiModel>> getNotifikasi() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.coreApiUrl}/notifikasi'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List).map((e) => NotifikasiModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
