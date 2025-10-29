const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const nodemailer = require('nodemailer');

// 🔹 Kullanıcı kayıt (Register)
router.post('/register', async (req, res) => {
  const { name, email, password, isWomanEntrepreneur } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({ message: 'Tüm alanlar zorunludur.' });
  }

  try {
    const [existingUser] = await db.query(
      'SELECT * FROM users WHERE email = ? OR name = ?',
      [email, name]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({ message: 'Bu e-posta veya kullanıcı adı zaten kayıtlı.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await db.query(
      'INSERT INTO users (name, email, password_hash, is_woman_entrepreneur) VALUES (?, ?, ?, ?)',
      [name, email, hashedPassword, isWomanEntrepreneur ? 1 : 0]
    );

    res.status(201).json({ message: 'Kayıt başarılı!' });
  } catch (err) {
    console.error('Kayıt hatası:', err);
    res.status(500).json({ message: 'Sunucu hatası.' });
  }
});


// 🔹 Kullanıcı girişi (Login)
router.post('/login', async (req, res) => {
  try {
    console.log("Login denemesi:", req.body);

    const { name, password } = req.body;

    if (!name || !password) {
      return res.status(400).json({ error: 'Kullanıcı adı ve şifre gerekli.' });
    }

    const [results] = await db.query('SELECT * FROM users WHERE name = ?', [name]);

    if (results.length === 0) {
      return res.status(401).json({ error: 'Kullanıcı bulunamadı.' });
    }

    const user = results[0];
    const isPasswordCorrect = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordCorrect) {
      return res.status(401).json({ error: 'Hatalı şifre.' });
    }

    const accessToken = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    const refreshToken = jwt.sign({ id: user.id }, process.env.JWT_REFRESH_SECRET, { expiresIn: '30d' });

    const refreshTokenExpire = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    await db.query(
      'UPDATE users SET refresh_token = ?, refresh_token_expire = ? WHERE id = ?',
      [refreshToken, refreshTokenExpire, user.id]
    );

    res.json({
      message: 'Giriş başarılı',
      access_token: accessToken,
      refresh_token: refreshToken,
      name: user.name,
      user_id: user.id,
      is_woman_entrepreneur: user.is_woman_entrepreneur === 1
    });

  } catch (err) {
    console.error('Login hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});


// 🔹 Token yenileme
router.post('/refresh', async (req, res) => {
  const { refresh_token } = req.body;

  if (!refresh_token) {
    return res.status(400).json({ error: 'Refresh token gerekli.' });
  }

  try {
    const [users] = await db.query('SELECT * FROM users WHERE refresh_token = ?', [refresh_token]);

    if (users.length === 0) {
      return res.status(403).json({ error: 'Geçersiz refresh token.' });
    }

    const user = users[0];

    jwt.verify(refresh_token, process.env.JWT_REFRESH_SECRET, async (err, decoded) => {
      if (err) {
        return res.status(403).json({ error: 'Refresh token süresi dolmuş.' });
      }

      const newAccessToken = jwt.sign({ id: decoded.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
      const newRefreshToken = jwt.sign({ id: decoded.id }, process.env.JWT_REFRESH_SECRET, { expiresIn: '30d' });
      const newRefreshTokenExpire = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 gün

      await db.query(
        'UPDATE users SET refresh_token = ?, refresh_token_expire = ? WHERE id = ?',
        [newRefreshToken, newRefreshTokenExpire, decoded.id]
      );

      res.json({
        access_token: newAccessToken,
        refresh_token: newRefreshToken
      });
    });

  } catch (err) {
    console.error('Refresh hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası.' });
  }
});


// 🔹 Şifre sıfırlama e-posta gönderme
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'E-posta gerekli.' });
  }

  try {
    const [userResult] = await db.query('SELECT id, email FROM users WHERE email = ?', [email]);
    if (userResult.length === 0) {
      return res.status(404).json({ message: 'Bu e-posta kayıtlı değil.' });
    }

    const user = userResult[0];
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 30);

    await db.query('DELETE FROM password_reset_tokens WHERE user_id = ?', [user.id]);
    await db.query(
      'INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES (?, ?, ?)',
      [user.id, token, expiresAt]
    );

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'officialdahliasdahlias@gmail.com',
        pass: 'imkt onkv qoly fsep',
      },
    });

    const resetLink = `dahlia://reset?token=${token}`;

    await transporter.sendMail({
      from: 'Dahlia <officialdahliasdahlias@gmail.com>',
      to: email,
      subject: 'Şifre Sıfırlama Bağlantısı',
      html: `
        <p>Merhaba,</p>
        <p>Şifreni sıfırlamak için aşağıdaki bağlantıya tıklayabilirsin:</p>
        <a href="${resetLink}">${resetLink}</a>
        <p>Bu bağlantı 30 dakika boyunca geçerlidir.</p>
      `,
    });

    res.json({ message: 'Şifre sıfırlama bağlantısı e-posta adresine gönderildi.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Sunucu hatası.' });
  }
});


// 🔹 Şifre sıfırlama işlemi (token ile)
router.post('/reset-password/:token', async (req, res) => {
  const { token } = req.params;
  const { password } = req.body;

  if (!password) {
    return res.status(400).json({ message: 'Yeni şifre gerekli.' });
  }

  try {
    const [tokenResult] = await db.query(
      'SELECT * FROM password_reset_tokens WHERE token = ? AND used = 0',
      [token]
    );

    if (tokenResult.length === 0) {
      return res.status(400).json({ message: 'Geçersiz veya kullanılmış bağlantı.' });
    }

    const tokenData = tokenResult[0];
    const now = new Date();

    if (now > tokenData.expires_at) {
      return res.status(400).json({ message: 'Bağlantı süresi dolmuş.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [
      hashedPassword,
      tokenData.user_id,
    ]);

    await db.query('UPDATE password_reset_tokens SET used = 1 WHERE id = ?', [tokenData.id]);

    res.json({ message: 'Şifre başarıyla sıfırlandı!' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Sunucu hatası.' });
  }
});

module.exports = router;
