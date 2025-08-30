const router = require('express').Router();
const { User } = require('../../../models');
const bcrypt = require('bcrypt');
const { signAccess, signRefresh } = require('../../middleware/auth');


// Login
router.post('/login', async (req,res)=>{
  const { email, password } = req.body;
  const user = await User.findOne({ where: { email }});
  if(!user) return res.status(400).json({ error: 'invalid_credentials' });
  const ok = await bcrypt.compare(password, user.password_hash || '');
  if(!ok) return res.status(400).json({ error: 'invalid_credentials' });
  const payload = { id: user.id, role: user.role, name: user.name, email: user.email };
  return res.json({ access_token: signAccess(payload), refresh_token: signRefresh(payload), user: payload });
});

// Signup
router.post('/signup', async (req, res) => {
  const { name, email, phone, company, password } = req.body;
  if (!email || !password || !name) return res.status(400).json({ error: 'missing_fields' });
  const exists = await User.findOne({ where: { email } });
  if (exists) return res.status(400).json({ error: 'email_exists' });
  const password_hash = await bcrypt.hash(password, 10);
  const user = await User.create({
    name,
    email,
    phone,
    password_hash,
    role: 'CLIENT',
    active: true
  });
  // TODO: Save company info if needed
  return res.json({ success: true, user: { id: user.id, name: user.name, email: user.email } });
});

const crypto = require('crypto');
const { Op } = require('sequelize');
const nodemailer = require('nodemailer');
const emailConfig = require('../../../config/email');
let resetTokens = {};

// Forgot Password (request reset)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ where: { email } });
  if (!user) return res.json({ success: true }); // Don't reveal existence
  // Generate token
  const token = crypto.randomBytes(32).toString('hex');
  resetTokens[token] = { userId: user.id, expires: Date.now() + 1000 * 60 * 30 };
  // Send email
  const transporter = nodemailer.createTransport({
    host: emailConfig.host,
    port: emailConfig.port,
    secure: emailConfig.secure,
    auth: emailConfig.auth,
  });
  const appLink = `crownsecurity://reset-password?token=${token}`;
  const mailOptions = {
    from: `${emailConfig.fromName} <${emailConfig.fromEmail}>`,
    to: email,
    subject: 'Crown Security Password Reset',
    html: `<p>Hello,</p>
      <p>You requested a password reset for your Crown Security account.</p>
      <p><a href="${appLink}"><b>Tap here to reset your password in the app</b></a></p>
      <p>If you did not request this, please ignore this email.</p>`,
  };
  try {
    await transporter.sendMail(mailOptions);
    console.log('Password reset email sent to', email);
  } catch (err) {
    console.error('Error sending email:', err);
  }
  return res.json({ success: true });
});

// Reset Password (with token)
router.post('/reset-password', async (req, res) => {
  const { token, password } = req.body;
  const entry = resetTokens[token];
  if (!entry || entry.expires < Date.now()) {
    return res.status(400).json({ error: 'invalid_or_expired_token' });
  }
  const user = await User.findByPk(entry.userId);
  if (!user) return res.status(400).json({ error: 'user_not_found' });
  user.password_hash = await bcrypt.hash(password, 10);
  await user.save();
  delete resetTokens[token];
  return res.json({ success: true });
});

router.post('/refresh', async (req,res)=>{
  // For simplicity, client will re-login when access expires in v1.
  return res.status(501).json({ error: 'not_implemented' });
});

module.exports = router;
