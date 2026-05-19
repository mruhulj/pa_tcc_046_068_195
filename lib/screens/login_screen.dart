import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.login(email, pass);
      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', res['data']['token']);
        await prefs.setString('user', jsonEncode(res['data']['user']));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        setState(() => _error = res['message'] ?? 'Login gagal');
      }
    } catch (e) {
      setState(() => _error = 'Gagal terhubung ke server');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15803d),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.eco, color: Color(0xFF16a34a), size: 44),
                ),
                const SizedBox(height: 12),
                const Text('SiPupuk', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Sistem Distribusi Pupuk Subsidi', style: TextStyle(color: Color(0xFFbbf7d0), fontSize: 13)),
                const SizedBox(height: 40),
                // Card Form
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Masuk ke Sistem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
                      const SizedBox(height: 20),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFfef2f2), borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: Color(0xFFdc2626), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 13))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Email
                      const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'email@domain.com',
                          hintStyle: const TextStyle(color: Color(0xFF9ca3af), fontSize: 14),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF9ca3af), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFf9fafb),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Password
                      const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: Color(0xFF9ca3af), fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF9ca3af), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9ca3af), size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFf9fafb),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16a34a),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Masuk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
