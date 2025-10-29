
const express = require('express');
const router = express.Router();
const db = require('../db');
const jwt = require('jsonwebtoken');

// Middleware: Token doğrulama
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Token gerekli.' });

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Token geçersiz.' });
    req.user = user;
    next();
  });
};

// 🔹 Tüm görevleri getir (kullanıcıya özel)
router.get('/challenges', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM challenges WHERE user_id = ? ORDER BY deadline ASC',
      [req.user.id]
    );
    res.json(rows);
  } catch (error) {
    console.error('Görev listeleme hatası:', error);
    res.status(500).json({ message: 'Sunucu hatası.' });
  }
});

// 🔹 Görev ekle
router.post('/challenges', verifyToken, async (req, res) => {
  const { title, description, deadline } = req.body;

  if (!title || !deadline) {
    return res.status(400).json({ message: 'Başlık ve tarih zorunludur.' });
  }

  try {
    const [result] = await db.query(
      'INSERT INTO challenges (user_id, title, description, deadline, progress) VALUES (?, ?, ?, ?, ?)',
      [req.user.id, title, description, deadline, 0]
    );

    // Yeni eklenen görevi al
    const [newTaskRows] = await db.query(
      'SELECT * FROM challenges WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json(newTaskRows[0]); // tüm görev objesi döner
  } catch (error) {
    console.error('Görev ekleme hatası:', error);
    res.status(500).json({ message: 'Sunucu hatası.' });
  }
});


// 🔹 Görev güncelle
router.put('/challenges/:id', verifyToken, async (req, res) => {
  const { title, description, deadline, progress } = req.body;
  const { id } = req.params;

  try {
    await db.query(
      'UPDATE challenges SET title=?, description=?, deadline=?, progress=? WHERE id=? AND user_id=?',
      [title, description, deadline, progress, id, req.user.id]
    );

    res.json({ message: 'Görev güncellendi.' });
  } catch (error) {
    console.error('Görev güncelleme hatası:', error);
    res.status(500).json({ message: 'Sunucu hatası.' });
  }
});

// 🔹 Görev sil
router.delete('/challenges/:id', verifyToken, async (req, res) => {
  const { id } = req.params;

  try {
    await db.query('DELETE FROM challenges WHERE id=? AND user_id=?', [
      id,
      req.user.id,
    ]);
    res.json({ message: 'Görev silindi.' });
  } catch (error) {
    console.error('Görev silme hatası:', error);
    res.status(500).json({ message: 'Sunucu hatası.' });
  }
});

module.exports = router;
