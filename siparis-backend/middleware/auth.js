const jwt = require('jsonwebtoken');

module.exports = function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.status(401).json({ error: 'Token eksik' });

  const token = authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token eksik' });

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) return res.status(403).json({ error: 'Geçersiz token' });
    req.user =  decoded; //{ id: decoded.id }; // Burada req.user yaratılıyor
    next();
  });
};
