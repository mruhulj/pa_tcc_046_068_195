const bcrypt = require('bcrypt');
const userModel = require('../models/userModel');
const { generateToken } = require('../config/jwt');
const logger = require('../utils/logger');

const SALT_ROUNDS = 12;

// Rate limiting sederhana untuk login
const loginAttempts = new Map();

const register = async (req, res) => {
  try {
    const { nama, email, password, role, wilayah_id } = req.body;

    // Validasi
    const errors = [];
    if (!nama || nama.trim().length < 3) errors.push('Nama minimal 3 karakter');
    if (!email || !email.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) errors.push('Format email tidak valid');
    if (!password || password.length < 8) errors.push('Password minimal 8 karakter');
    if (!['dinas', 'distributor', 'ketua_tani'].includes(role)) errors.push('Role tidak valid');

    if (errors.length > 0) {
      return res.status(400).json({ success: false, message: 'Validasi gagal', errors });
    }

    // Cek email duplikat
    const existing = await userModel.findByEmail(email);
    if (existing) {
      return res.status(400).json({ success: false, message: 'Email sudah terdaftar' });
    }

    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const user = await userModel.create({ nama: nama.trim(), email, password: hashedPassword, role, wilayah_id });

    logger.info('User baru terdaftar', { email, role });

    return res.status(201).json({
      success: true,
      message: 'Registrasi berhasil',
      data: user
    });
  } catch (err) {
    logger.error('Register error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email dan password wajib diisi' });
    }

    // Rate limiting: max 10 percobaan per 15 menit per IP
    const ip = req.ip;
    const now = Date.now();
    const window = 15 * 60 * 1000;
    const attempts = (loginAttempts.get(ip) || []).filter(t => t > now - window);

    if (attempts.length >= 10) {
      return res.status(429).json({ success: false, message: 'Terlalu banyak percobaan login. Coba lagi 15 menit lagi.' });
    }

    const user = await userModel.findByEmail(email);
    if (!user) {
      attempts.push(now);
      loginAttempts.set(ip, attempts);
      return res.status(401).json({ success: false, message: 'Email atau password salah' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      attempts.push(now);
      loginAttempts.set(ip, attempts);
      return res.status(401).json({ success: false, message: 'Email atau password salah' });
    }

    // Reset attempts setelah login sukses
    loginAttempts.delete(ip);

    const token = generateToken({
      user_id: user.id,
      nama: user.nama,
      email: user.email,
      role: user.role,
      wilayah_id: user.wilayah_id
    });

    logger.info('User login berhasil', { email, role: user.role });

    return res.status(200).json({
      success: true,
      message: 'Login berhasil',
      data: {
        token,
        expires_in: process.env.JWT_EXPIRES_IN || '24h',
        user: {
          id: user.id,
          nama: user.nama,
          email: user.email,
          role: user.role,
          wilayah_id: user.wilayah_id
        }
      }
    });
  } catch (err) {
    logger.error('Login error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const me = async (req, res) => {
  try {
    const user = await userModel.findById(req.user.user_id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }
    return res.status(200).json({ success: true, data: user });
  } catch (err) {
    logger.error('Get me error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

const changePassword = async (req, res) => {
  try {
    const { password_lama, password_baru } = req.body;

    if (!password_lama || !password_baru) {
      return res.status(400).json({ success: false, message: 'Password lama dan baru wajib diisi' });
    }
    if (password_baru.length < 8) {
      return res.status(400).json({ success: false, message: 'Password baru minimal 8 karakter' });
    }

    const user = await userModel.findById(req.user.user_id);
    // Ambil password hash dari DB
    const [rows] = await require('../config/database').execute(
      'SELECT password FROM users WHERE id = ?', [req.user.user_id]
    );
    const isMatch = await bcrypt.compare(password_lama, rows[0].password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Password lama tidak sesuai' });
    }

    const hashed = await bcrypt.hash(password_baru, SALT_ROUNDS);
    await userModel.updatePassword(req.user.user_id, hashed);

    logger.info('Password diubah', { user_id: req.user.user_id });

    return res.status(200).json({ success: true, message: 'Password berhasil diubah' });
  } catch (err) {
    logger.error('Change password error', { error: err.message });
    return res.status(500).json({ success: false, message: 'Terjadi kesalahan server' });
  }
};

module.exports = { register, login, me, changePassword };
