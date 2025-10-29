const express = require('express');
const router = express.Router();
const verifyToken = require('../middleware/auth');
const db = require('../db'); // mysql bağlantı
const path = require('path');
const fs = require('fs');
const multer = require('multer');

// Profile image upload setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '..', 'upload/profile_images'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}${ext}`);
  }
});
const uploadMiddleware = multer({ storage }); // isim çakışmasını önledik

// 🔹 Kendi profilini gör
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await db.query(
      'SELECT id, name, email, bio, profile_image_url FROM users WHERE id = ?',
      [userId]
    );

    if (!rows.length) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 🔹 Profil güncelle
router.put('/update-profile', verifyToken, uploadMiddleware.single('profile_image'), async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, email, bio } = req.body;
    let profileImagePath = null;

    if (req.file) {
      profileImagePath = `profile_images/${req.file.filename}`;

      // Eski resmi sil
      const [rows] = await db.query('SELECT profile_image_url FROM users WHERE id = ?', [userId]);
      const oldImage = rows[0]?.profile_image_url;
      if (oldImage && fs.existsSync(path.join(__dirname, '..', oldImage))) {
        fs.unlinkSync(path.join(__dirname, '..', oldImage));
      }
    }

    // Dinamik SQL update
    let fields = [], values = [];
    if (name && name.trim() !== '') { fields.push('name = ?'); values.push(name.trim()); }
    if (email && email.trim() !== '') { fields.push('email = ?'); values.push(email.trim()); }
    if (bio && bio.trim() !== '') { fields.push('bio = ?'); values.push(bio.trim()); }
    if (profileImagePath) { fields.push('profile_image_url = ?'); values.push(profileImagePath); }

    if (fields.length === 0) return res.status(400).json({ error: 'Güncellenecek veri yok' });

    values.push(userId);
    const sql = `UPDATE users SET ${fields.join(', ')} WHERE id = ?`;
    await db.query(sql, values);

    const [updatedRows] = await db.query(
      'SELECT id, name, email, bio, profile_image_url FROM users WHERE id = ?',
      [userId]
    );

    res.json({
      success: true,
      user: updatedRows[0]
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 🔹 Başkasının profilini gör (ID ile, token gerekmez, email hariç)
router.get('/profile/:id', async (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    const [rows] = await db.query(
      'SELECT id, name, bio, profile_image_url FROM users WHERE id = ?',
      [userId]
    );

    if (!rows.length) return res.status(404).json({ error: 'Kullanıcı bulunamadı' });

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

module.exports = router;
