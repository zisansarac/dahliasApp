require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const db = require('./db'); // MySQL bağlantı

// Route dosyaları
const authRoutes = require('./routes/auth');
const ordersRoutes = require('./routes/orders');
const userRoutes = require('./routes/user');
const womenMapRoutes = require('./routes/womenMap');
const communityRoutes = require('./routes/community');
const challengesRoutes = require('./routes/challenges');

const app = express();

// Middlewares
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

// ⚡ KRİTİK DÜZELTME 1: Resim URL'sinin başında '/profile_images' varsa,
// Express'in bunu 'upload/profile_images' klasörüne yönlendirmesini sağla.
app.use(
  '/profile_images', 
  express.static(path.join(__dirname, 'upload', 'profile_images'))
);

// Statik dosyalar için mevcut ayar (diğer dosyalar için gerekli olabilir)
app.use('/upload', express.static(path.join(__dirname, 'upload')));


// Rotalar
app.use('/api/auth', authRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/user', userRoutes);
app.use('/api/women-map', womenMapRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/challenges', challengesRoutes);

// Sunucu başlatma
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on port ${PORT}`);
});
