const express = require('express');
const router = express.Router();
const db = require('../db');

// Kadın girişimcileri getir
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM entrepreneurs');
    res.json(rows);
  } catch (err) {
    console.error('Kadın girişimciler alınamadı:', err);
    res.status(500).json({ error: 'Veritabanı hatası' });
  }
});

module.exports = router;
