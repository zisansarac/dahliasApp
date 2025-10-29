const express = require('express');
const router = express.Router();
const db = require('../db');
const verifyToken = require('../middleware/auth');

// ➕ Yeni topluluk mesajı ekleme
router.post('/',verifyToken, async (req, res) => {
  const userId = req.user.id;
  const { title, body, image_url, is_public } = req.body;

  if (!body) {
    return res.status(400).json({ error: 'body zorunludur' });
  }

  try {
    await db.query(
      `INSERT INTO community_posts 
        (user_id, title, body, image_url, is_public) 
       VALUES (?, ?, ?, ?, ?)`,
      [userId, title || null, body, image_url || null, is_public ? 1 : 1]
    );
    res.status(201).json({ message: 'Mesaj başarıyla paylaşıldı' });
  } catch (error) {
    console.error('Ekleme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 📥 Tüm mesajları listeleme (yeniden eskiye)
router.get('/',verifyToken, async (req, res) => {
  const userId = req.user.id;

  try {
    const [rows] = await db.query(`
      SELECT cp.*, u.name AS author_name,
        EXISTS (
          SELECT 1 FROM community_likes
          WHERE user_id = ? AND post_id = cp.id
        ) AS isLiked,
        (SELECT COUNT(*) FROM community_likes WHERE post_id = cp.id) AS like_count
      FROM community_posts cp
      JOIN users u ON cp.user_id = u.id
      ORDER BY cp.created_at DESC
    `, [userId]);

    res.json(rows);
  } catch (error) {
    console.error('Listeleme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 🔁 Mesaj güncelleme
router.put('/:id', verifyToken,async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { title, body, image_url, is_public } = req.body;

  try {
    const [result] = await db.query(
      `UPDATE community_posts SET title = ?, body = ?, image_url = ?, is_public = ?
       WHERE id = ? AND user_id = ?`,
      [title || null, body, image_url || null, is_public ? 1 : 1, id, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ error: 'Bu postu düzenleme yetkiniz yok' });
    }

    res.json({ message: 'Post güncellendi' });
  } catch (err) {
    console.error('Post güncelleme hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// ❌ Sadece kendi mesajını silme
router.delete('/:id', verifyToken, async (req, res) => {
  const { id } = req.params;

  const userId = req.user && req.user.id ? req.user.id : null;

  console.log(`[DELETE POST DEBUG] Attempting to delete Post ID: ${id} by User ID: ${userId}`);

    if (!userId) {
        // Eğer token doğrulaması (verifyToken) başarısız olduysa buraya düşmemeli, ama düştüyse 401 döndür.
        return res.status(401).json({ error: 'Kullanıcı doğrulanamadı.' }); 
    }

  try {
    console.log(`[DELETE POST DEBUG] Attempting to delete Post ID: ${id} by User ID: ${userId}`);

    const [result] = await db.query(
      'DELETE FROM community_posts WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    console.log(`[DELETE POST DEBUG] Affected Rows: ${result.affectedRows}`);

    if (result.affectedRows === 0) {
      return res.status(403).json({ error: 'Bu mesajı silme yetkiniz yok' });
    }

    res.json({ message: 'Mesaj silindi' });
  } catch (error) {
    console.error('Silme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 👍 Beğeni ekle/kaldır (toggle)
router.post('/:id/like', verifyToken, async (req, res) => {
  const postId = req.params.id;

  const userId = req.user.id;

  try {
    
    const [rows] = await db.query(
      'SELECT * FROM community_likes WHERE user_id = ? AND post_id = ?',
      [userId, postId]
    );

    if (rows.length > 0) {
      await db.query(
        'DELETE FROM community_likes WHERE user_id = ? AND post_id = ?',
        [userId, postId]
      );
      return res.json({ liked: false });
    } else {
      await db.query(
        'INSERT INTO community_likes (user_id, post_id) VALUES (?, ?)',
        [userId, postId]
      );
      return res.json({ liked: true });
    }
  } catch (error) {
    console.error('Beğeni hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 💬 Yorum ekleme
router.post('/:id/comment', verifyToken, async (req, res) => {
  const postId = req.params.id;
  const userId = req.user.id;
  const { content, parent_comment_id } = req.body;

  if (!content) {
    return res.status(400).json({ error: 'content zorunludur' });
  }

  try {
    await db.query(
      'INSERT INTO post_comments (post_id, user_id, content, parent_comment_id) VALUES (?, ?, ?, ?)',
      [postId, userId, content, parent_comment_id || null]
    );
    res.status(201).json({ message: 'Yorum eklendi' });
  } catch (error) {
    console.error('Yorum ekleme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 📥 Yorumları listeleme
router.get('/:id/comments', verifyToken, async (req, res) => {
  const postId = req.params.id;

  try {
    const [rows] = await db.query(
      `SELECT c.*, u.name AS author_name
       FROM post_comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.post_id = ?
       ORDER BY c.created_at DESC`,
      [postId]
    );
    res.json(rows);
  } catch (error) {
    console.error('Yorum listeleme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// ❌ Yorum silme
router.delete('/comment/:commentId', verifyToken, async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.id;

  try {
    const [result] = await db.query(
      'DELETE FROM post_comments WHERE id = ? AND user_id = ?',
      [commentId, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ error: 'Bu yorumu silme yetkiniz yok' });
    }

    res.json({ message: 'Yorum silindi' });
  } catch (error) {
    console.error('Yorum silme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// 🔁 Yorum güncelleme
router.put('/:postId/comments/:commentId', verifyToken ,async (req, res) => {
  const { commentId, postId } = req.params;
  const userId = req.user.id;
  const { content } = req.body;


  if (!content) {
    return res.status(400).json({ error: 'content zorunludur' });
  }

  try {
    const [result] = await db.query(
      'UPDATE post_comments SET content = ? WHERE id = ? AND user_id = ? AND post_id = ?',
      [content, commentId, userId, postId]
    );

    if (result.affectedRows === 0) {
      return res.status(403).json({ error: 'Bu yorumu düzenleme yetkiniz yok' });
    }

    res.json({ message: 'Yorum güncellendi' });
  } catch (err) {
    console.error('Yorum güncelleme hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

module.exports = router;
