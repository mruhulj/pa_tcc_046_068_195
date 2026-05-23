-- ============================================
-- INIT DATABASE: pupuk_subsidi
-- Jalankan script ini di Cloud SQL Studio
-- atau via mysql client setelah instance ready
-- ============================================

CREATE DATABASE IF NOT EXISTS pupuk_subsidi;
USE pupuk_subsidi;

-- 1. WILAYAH
CREATE TABLE IF NOT EXISTS wilayah (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nama VARCHAR(100) NOT NULL,
  provinsi VARCHAR(100),
  kabupaten VARCHAR(100),
  kecamatan VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. USERS
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nama VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('dinas','distributor','ketua_tani') NOT NULL,
  wilayah_id INT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (wilayah_id) REFERENCES wilayah(id)
);

-- 3. DISTRIBUTOR
CREATE TABLE IF NOT EXISTS distributor (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nama VARCHAR(100) NOT NULL,
  alamat TEXT,
  telepon VARCHAR(20),
  wilayah_id INT,
  user_id INT,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (wilayah_id) REFERENCES wilayah(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 4. KELOMPOK TANI
CREATE TABLE IF NOT EXISTS kelompok_tani (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nama VARCHAR(100) NOT NULL,
  ketua_nama VARCHAR(100),
  alamat TEXT,
  telepon VARCHAR(20),
  wilayah_id INT,
  user_id INT,
  jumlah_anggota INT DEFAULT 0,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (wilayah_id) REFERENCES wilayah(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 5. KUOTA WILAYAH
CREATE TABLE IF NOT EXISTS kuota_wilayah (
  id INT PRIMARY KEY AUTO_INCREMENT,
  wilayah_id INT NOT NULL,
  jenis_pupuk ENUM('Urea','NPK','SP36','ZA') NOT NULL,
  periode_bulan TINYINT NOT NULL,
  periode_tahun YEAR NOT NULL,
  total_kuota_kg DECIMAL(10,2) NOT NULL,
  sisa_kuota_kg DECIMAL(10,2) NOT NULL,
  created_by INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (wilayah_id) REFERENCES wilayah(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

-- 6. ALOKASI
CREATE TABLE IF NOT EXISTS alokasi (
  id INT PRIMARY KEY AUTO_INCREMENT,
  kuota_id INT NOT NULL,
  distributor_id INT NOT NULL,
  kelompok_id INT NOT NULL,
  jenis_pupuk ENUM('Urea','NPK','SP36','ZA') NOT NULL,
  jumlah_kg DECIMAL(10,2) NOT NULL,
  status ENUM('pending','disetujui','ditolak') DEFAULT 'pending',
  tanggal_alokasi DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (kuota_id) REFERENCES kuota_wilayah(id),
  FOREIGN KEY (distributor_id) REFERENCES distributor(id),
  FOREIGN KEY (kelompok_id) REFERENCES kelompok_tani(id)
);

-- 7. DISTRIBUSI
CREATE TABLE IF NOT EXISTS distribusi (
  id INT PRIMARY KEY AUTO_INCREMENT,
  alokasi_id INT NOT NULL,
  distributor_id INT NOT NULL,
  kelompok_id INT NOT NULL,
  tanggal_kirim DATE,
  jumlah_kg DECIMAL(10,2) NOT NULL,
  status ENUM('dikirim','diterima','bermasalah') DEFAULT 'dikirim',
  catatan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (alokasi_id) REFERENCES alokasi(id),
  FOREIGN KEY (distributor_id) REFERENCES distributor(id),
  FOREIGN KEY (kelompok_id) REFERENCES kelompok_tani(id)
);

-- 8. PENERIMAAN
CREATE TABLE IF NOT EXISTS penerimaan (
  id INT PRIMARY KEY AUTO_INCREMENT,
  distribusi_id INT NOT NULL,
  kelompok_id INT NOT NULL,
  jumlah_diterima DECIMAL(10,2) NOT NULL,
  tanggal_terima DATE,
  status_verifikasi ENUM('pending','diverifikasi','ditolak') DEFAULT 'pending',
  verified_by INT,
  foto_url VARCHAR(500),
  catatan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (distribusi_id) REFERENCES distribusi(id),
  FOREIGN KEY (kelompok_id) REFERENCES kelompok_tani(id),
  FOREIGN KEY (verified_by) REFERENCES users(id)
);

-- INDEX
CREATE INDEX idx_distribusi_status ON distribusi(status);
CREATE INDEX idx_kuota_periode ON kuota_wilayah(wilayah_id, periode_bulan, periode_tahun);
CREATE INDEX idx_penerimaan_status ON penerimaan(status_verifikasi);
CREATE INDEX idx_alokasi_kelompok ON alokasi(kelompok_id);

-- ============================================
-- SEED DATA AWAL
-- ============================================

-- Wilayah
INSERT INTO wilayah (nama, provinsi, kabupaten, kecamatan) VALUES
('Wilayah Srandakan', 'DI Yogyakarta', 'Bantul', 'Srandakan'),
('Wilayah Bambanglipuro', 'DI Yogyakarta', 'Bantul', 'Bambanglipuro'),
('Wilayah Pandak', 'DI Yogyakarta', 'Bantul', 'Pandak');

-- Users (password: password123 -> bcrypt hash)
-- Gunakan script Node.js untuk generate hash sebelum insert, atau register via API
-- Contoh hash untuk "password123" dengan salt 12:
INSERT INTO users (nama, email, password, role, wilayah_id) VALUES
('Admin Dinas', 'dinas@sipupuk.id', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhN8h4y7jtjMoqUhCe5JQm', 'dinas', 1),
('CV Maju Jaya', 'distributor@sipupuk.id', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhN8h4y7jtjMoqUhCe5JQm', 'distributor', 1),
('Pak Slamet', 'tani@sipupuk.id', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMqJqhN8h4y7jtjMoqUhCe5JQm', 'ketua_tani', 1);

-- CATATAN: Hash di atas BELUM VALID.
-- Gunakan cara ini untuk generate password yang benar:
-- node -e "const b=require('bcrypt');b.hash('password123',12).then(h=>console.log(h))"
-- Lalu copy hasilnya ke sini, atau gunakan API register.

-- Distributor
INSERT INTO distributor (nama, alamat, telepon, wilayah_id, user_id, status) VALUES
('CV Maju Jaya', 'Jl. Parangtritis No. 10, Bantul', '081234567890', 1, 2, 'aktif');

-- Kelompok Tani
INSERT INTO kelompok_tani (nama, ketua_nama, alamat, telepon, wilayah_id, jumlah_anggota, user_id, status) VALUES
('Tani Makmur', 'Pak Slamet', 'Dusun Ngentak RT 01, Srandakan', '082233445566', 1, 25, 3, 'aktif'),
('Berkah Tani', 'Bu Rahayu', 'Dusun Glagah RT 02, Srandakan', '083344556677', 1, 18, NULL, 'aktif');

-- Kuota
INSERT INTO kuota_wilayah (wilayah_id, jenis_pupuk, periode_bulan, periode_tahun, total_kuota_kg, sisa_kuota_kg, created_by) VALUES
(1, 'Urea', 5, 2025, 5000.00, 5000.00, 1),
(1, 'NPK', 5, 2025, 3000.00, 3000.00, 1),
(2, 'Urea', 5, 2025, 4000.00, 4000.00, 1);
