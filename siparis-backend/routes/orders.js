const express = require('express');
const router = express.Router();
const db = require('../db');
const verifyToken = require('../middleware/auth');

// 🔹 Tüm siparişleri getir (kullanıcıya özel)
router.get('/', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    if (!userId) return res.status(401).json({ error: 'Kullanıcı kimliği bulunamadı.' });

    const [rows] = await db.query(
      'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    );

    const formattedOrders = rows.map(order => {
      const createdAt = new Date(order.created_at);
      return {
        ...order,
        date: createdAt.toISOString().split('T')[0],
        time: createdAt.toTimeString().split(' ')[0].slice(0, 5),
      };
    });

    res.json(formattedOrders);
  } catch (err) {
    console.error('Sipariş listeleme hatası:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 Yeni sipariş oluştur
router.post('/', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      customer_name,
      customer_phone,
      description,
      total_amount,
      status,
      scheduled_at
    } = req.body;

    if (!userId) return res.status(401).json({ error: 'Kullanıcı kimliği bulunamadı.' });

    let validScheduledAt = null;
    
    // Flutter'dan gelen ISO string'i Date objesine çevir
     if (scheduled_at) {
         const dateObj = new Date(scheduled_at);
        // Geçerli bir tarih objesi ise kullan
       // NOT: MySQL/MariaDB, Date objelerini otomatik olarak TIMESTAMP/DATETIME formatına çevirebilir.
      if (!isNaN(dateObj.getTime())) { 
          validScheduledAt = dateObj;
     }
    }

    await db.query(
      `INSERT INTO orders
       (user_id, customer_name, customer_phone, description, total_amount, status, scheduled_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        userId,
        customer_name,
        customer_phone,
        description,
        total_amount || 0,
        status || 'pending',
        validScheduledAt
      ]
    );

    res.status(201).json({ message: 'Sipariş başarıyla oluşturuldu.' });
  } catch (err) {
    console.error('Sipariş oluşturma hatası:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 Sipariş durumu güncelle
router.patch('/:id/status', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { status } = req.body;

    const [result] = await db.query(
      'UPDATE orders SET status = ? WHERE id = ? AND user_id = ?',
      [status, id, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ message: 'Bu siparişi güncelleme yetkiniz yok.' });
    }

    res.json({ message: 'Sipariş durumu güncellendi.' });
  } catch (err) {
    console.error('Durum güncelleme hatası:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 Sipariş detaylarını güncelle
router.put('/:id', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const {
      customer_name,
      customer_phone,
      description,
      total_amount,
      status,
      scheduled_at
    } = req.body;

    const [result] = await db.query(
      `UPDATE orders SET
         customer_name = ?, customer_phone = ?, description = ?, total_amount = ?,
         status = ?, scheduled_at = ?
       WHERE id = ? AND user_id = ?`,
      [
        customer_name,
        customer_phone,
        description,
        total_amount || 0,
        status,
        scheduled_at || null,
        id,
        userId
      ]
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ message: 'Güncelleme yetkiniz yok veya sipariş bulunamadı.' });
    }

    res.json({ message: 'Sipariş başarıyla güncellendi.' });
  } catch (err) {
    console.error('Sipariş güncelleme hatası:', err);
    res.status(500).json({ error: err.message });
  }
});

// 🔹 Siparişi sil
// 🔹 Siparişi sil
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // 🕵️ ADIM 1: Gelen verileri kontrol et
    console.log(`[DELETE START] User ID: ${userId}, Order ID: ${id}`);
    
    const [result] = await db.query(
      'DELETE FROM orders WHERE id = ? AND user_id = ?',
      [id, userId]
  );

    // 🕵️ ADIM 2: Sorgu sonucunu kontrol et
    console.log(`[DELETE RESULT] Affected Rows: ${result.affectedRows}`);
    
  if (result.affectedRows === 0) {
    return res.status(403).json({ message: 'Silme yetkiniz yok veya sipariş bulunamadı.' });
 }

   res.json({ message: 'Sipariş başarıyla silindi.' });
  } catch (err) {
  console.error('Sipariş silme hatası:', err);
    // Hata durumunda 500 dönülmeli (sizin kodunuz zaten yapıyor)
    res.status(500).json({ error: err.message }); 
 }
});

module.exports = router;
