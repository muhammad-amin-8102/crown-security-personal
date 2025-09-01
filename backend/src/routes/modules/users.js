const router = require('express').Router();
const { auth } = require('../../middleware/auth');
const { allow } = require('../../middleware/roles');
const { User } = require('../../../models');
const bcrypt = require('bcrypt');

// List all users
router.get('/', auth(), allow('ADMIN'), async (req, res) => {
  try {
    const { role } = req.query;
    const where = {};
    if (role) where.role = role;
    
    const users = await User.findAll({
      where,
      attributes: { exclude: ['password_hash'] },
      order: [['createdAt', 'DESC']]
    });
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get single user
router.get('/:id', auth(), allow('ADMIN'), async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id, {
      attributes: { exclude: ['password_hash'] }
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create user
router.post('/', auth(), allow('ADMIN'), async (req, res) => {
  try {
    const { password, ...userData } = req.body;
    
    // Hash password if provided
    if (password) {
      userData.password_hash = await bcrypt.hash(password, 10);
    }
    
    const user = await User.create(userData);
    
    // Return user without password hash
    const { password_hash, ...userResponse } = user.toJSON();
    res.status(201).json(userResponse);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Update user
router.put('/:id', auth(), allow('ADMIN'), async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const { password, ...updateData } = req.body;
    
    // Hash password if provided
    if (password) {
      updateData.password_hash = await bcrypt.hash(password, 10);
    }
    
    await user.update(updateData);
    
    // Return updated user without password hash
    const { password_hash, ...userResponse } = user.toJSON();
    res.json(userResponse);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Delete user
router.delete('/:id', auth(), allow('ADMIN'), async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    await user.destroy();
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
