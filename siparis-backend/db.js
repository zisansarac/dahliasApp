const mysql = require('mysql2');

const pool = mysql.createPool({
  host: 'localhost',          // MySQL sunucusu
  user: 'root',               // phpMyAdmin kullanıcı adı (genelde root)
  password: '',               // şifre yoksa boş bırak
  database: 'dahlias_new'     // biraz önce oluşturduğun veritabanı adı
});

module.exports = pool.promise();
