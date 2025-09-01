const jwt = require('jsonwebtoken');

// Default TTLs to 30 days if env not set
const THIRTY_DAYS = 60 * 60 * 24 * 30; // seconds
function signAccess(payload){ return jwt.sign(payload, process.env.JWT_ACCESS_SECRET, { expiresIn: +process.env.JWT_ACCESS_TTL || THIRTY_DAYS }); }
function signRefresh(payload){ return jwt.sign(payload, process.env.JWT_REFRESH_SECRET, { expiresIn: +process.env.JWT_REFRESH_TTL || THIRTY_DAYS }); }

function auth(required = true){
  return (req, res, next) => {
    const hdr = req.headers.authorization || '';
    const token = hdr.startsWith('Bearer ') ? hdr.slice(7) : null;
    if(!token){
      if(required) return res.status(401).json({error:'unauthorized'});
      req.user = null; return next();
    }
    try{
      req.user = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
      return next();
    }catch(e){ return res.status(401).json({error:'invalid_token'}); }
  };
}

module.exports = { auth, signAccess, signRefresh };
