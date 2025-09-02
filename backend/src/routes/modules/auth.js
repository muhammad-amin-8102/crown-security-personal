const router = require('express').Router();
const { User } = require('../../../models');
const bcrypt = require('bcryptjs');
const { signAccess, signRefresh } = require('../../middleware/auth');


// Login
router.post('/login', async (req, res) => {
  try {
    console.log('🔐 Login attempt received');
    console.log('📥 Request body:', JSON.stringify(req.body, null, 2));
    console.log('📤 Request headers:', JSON.stringify(req.headers, null, 2));
    
    const { email, password } = req.body;
    
    // Validate input
    if (!email || !password) {
      console.log('❌ Missing fields - email:', !!email, 'password:', !!password);
      return res.status(400).json({ 
        error: 'missing_fields', 
        message: 'Email and password are required' 
      });
    }
    
    console.log('🔍 Looking for user with email:', email);
    
    // Find user
    const user = await User.findOne({ where: { email } });
    console.log('👤 User found:', !!user);
    if (user) {
      console.log('📋 User details:', {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        active: user.active,
        hasPassword: !!user.password_hash,
        passwordLength: user.password_hash ? user.password_hash.length : 0
      });
    }
    
    if (!user) {
      console.log('❌ User not found for email:', email);
      return res.status(400).json({ 
        error: 'invalid_credentials', 
        message: 'Invalid email or password' 
      });
    }
    
    console.log('🔑 Comparing password...');
    console.log('🔑 Password provided length:', password.length);
    console.log('🔑 Hash in database length:', user.password_hash ? user.password_hash.length : 0);
    
    // Check password
    const ok = await bcrypt.compare(password, user.password_hash || '');
    console.log('✅ Password comparison result:', ok);
    
    if (!ok) {
      console.log('❌ Password mismatch for user:', email);
      return res.status(400).json({ 
        error: 'invalid_credentials', 
        message: 'Invalid email or password' 
      });
    }
    
    console.log('🎉 Login successful for user:', email);
    
    // Create payload and tokens
    const payload = { 
      id: user.id, 
      role: user.role, 
      name: user.name, 
      email: user.email 
    };
    
    console.log('🎫 Generated payload:', JSON.stringify(payload, null, 2));
    
    const response = { 
      access_token: signAccess(payload), 
      refresh_token: signRefresh(payload), 
      user: payload 
    };
    
    console.log('📤 Sending successful login response');
    return res.json(response);
  } catch (error) {
    console.error('💥 Login error:', error);
    console.error('💥 Error stack:', error.stack);
    return res.status(500).json({ 
      error: 'server_error', 
      message: 'Internal server error during login',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
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
