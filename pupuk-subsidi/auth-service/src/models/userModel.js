const db = require('../config/database');

const findByEmail = async (email) => {
  const [rows] = await db.execute(
    'SELECT * FROM users WHERE email = ? AND is_active = true',
    [email]
  );
  return rows[0] || null;
};

const findById = async (id) => {
  const [rows] = await db.execute(
    'SELECT id, nama, email, role, wilayah_id, is_active, created_at FROM users WHERE id = ?',
    [id]
  );
  return rows[0] || null;
};

const create = async ({ nama, email, password, role, wilayah_id }) => {
  const [result] = await db.execute(
    'INSERT INTO users (nama, email, password, role, wilayah_id) VALUES (?, ?, ?, ?, ?)',
    [nama, email, password, role, wilayah_id || null]
  );
  return { id: result.insertId, nama, email, role };
};

const updatePassword = async (id, hashedPassword) => {
  await db.execute('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, id]);
};

module.exports = { findByEmail, findById, create, updatePassword };
