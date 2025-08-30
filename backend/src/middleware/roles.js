const allow = (...roles) => (req,res,next)=>{
  if(!req.user) return res.status(401).json({error:'unauthorized'});
  if(!roles.includes(req.user.role)) return res.status(403).json({error:'forbidden'});
  next();
};
module.exports = { allow };
