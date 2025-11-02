const express = require('express');
const path = require('path');
const bcrypt = require('bcryptjs');
const { query } = require('./db');

const app = express();
const PORT = 3000;

// Middleware - Increase body size limit for base64 images
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use(express.static(__dirname));

// ============================================
// API ROUTES
// ============================================

// Register API
// Admin email(s) - auto-assign admin role
const ADMIN_EMAILS = ['mayuresh.tardekar25@spit.ac.in', 'admin@spit.ac.in'];

app.post('/api/register', async (req, res) => {
  try {
    const { name, ucid, email, password, phone, department, year, semester } = req.body;
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Check if email is admin
    const role = ADMIN_EMAILS.includes(email.toLowerCase()) ? 'admin' : 'student';
    
    // Insert user with role
    const result = await query(
      'INSERT INTO users (name, ucid, email, password, role, phone, department, year, semester) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [name, ucid, email, hashedPassword, role, phone, department, year, semester]
    );
    
    res.json({ success: true, userId: result.insertId, role: role });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
});

// Login API
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Get user
    const users = await query('SELECT * FROM users WHERE email = ?', [email]);
    
    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    const user = users[0];
    
    // Verify password
    const isValid = await bcrypt.compare(password, user.password);
    
    if (!isValid) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
    
    // Update last login
    await query('UPDATE users SET last_login = NOW() WHERE id = ?', [user.id]);
    
    // Return user data (without password)
    delete user.password;
    res.json({ success: true, user });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get all items
app.get('/api/items', async (req, res) => {
  try {
    const items = await query(`
      SELECT i.*, u.name as reporter_name, l.name as location_name
      FROM items i
      JOIN users u ON i.user_id = u.id
      LEFT JOIN locations l ON i.location_id = l.id
      WHERE i.status = 'Open'
      ORDER BY i.created_at DESC
    `);
    res.json(items);
  } catch (error) {
    console.error('Get items error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get user's posts
app.get('/api/myposts/:userId', async (req, res) => {
  try {
    const items = await query('SELECT * FROM items WHERE user_id = ? ORDER BY created_at DESC', [req.params.userId]);
    res.json(items);
  } catch (error) {
    console.error('Get myposts error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create new item
app.post('/api/items', async (req, res) => {
  try {
    const { user_id, title, description, category, location_text, type, contact_info, image_url, color, found_date } = req.body;
    
    // Validate required fields
    if (!user_id || !title || !type || !contact_info) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }
    
    const result = await query(
      'INSERT INTO items (user_id, title, description, category, location_text, type, contact_info, image_url, color, found_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [user_id, title, description || '', category || 'Other', location_text || '', type, contact_info, image_url || null, color || null, found_date || new Date().toISOString().split('T')[0]]
    );
    
    res.json({ success: true, itemId: result.insertId });
  } catch (error) {
    console.error('Create item error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Delete item
app.delete('/api/items/:id', async (req, res) => {
  try {
    await query('DELETE FROM items WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (error) {
    console.error('Delete item error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get locations
app.get('/api/locations', async (req, res) => {
  try {
    const locations = await query('SELECT * FROM locations WHERE is_active = 1 ORDER BY display_order');
    res.json(locations);
  } catch (error) {
    console.error('Get locations error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Claims API
app.post('/api/claims', async (req, res) => {
  try {
    const { item_id, claimant_user_id, message, proof_image } = req.body;

    const query = `
      INSERT INTO claims (item_id, claimant_user_id, message, proof_image)
      VALUES (?, ?, ?, ?)
    `;

    const [result] = await db.execute(query, [
      item_id,
      claimant_user_id,
      message || null,
      proof_image || null
    ]);

    // Get item details for notification
    const [items] = await db.execute(
      'SELECT title, user_id FROM items WHERE id = ?',
      [item_id]
    );

    if (items.length > 0) {
      const item = items[0];
      
      // Create notification for item owner
      const notifQuery = `
        INSERT INTO notifications (user_id, title, message, type, related_item_id, related_claim_id)
        VALUES (?, ?, ?, 'claim', ?, ?)
      `;
      
      await db.execute(notifQuery, [
        item.user_id,
        'New Claim on Your Item',
        `Someone has claimed your found item: "${item.title}"`,
        item_id,
        result.insertId
      ]);
    }

    res.json({ 
      success: true, 
      message: 'Claim submitted successfully',
      claimId: result.insertId 
    });
  } catch (error) {
    console.error('Submit claim error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get claims for an item
app.get('/api/items/:itemId/claims', async (req, res) => {
  try {
    const { itemId } = req.params;
    
    const query = `
      SELECT c.*, u.name as claimant_name, u.email as claimant_email
      FROM claims c
      JOIN users u ON c.claimant_user_id = u.id
      WHERE c.item_id = ?
      ORDER BY c.created_at DESC
    `;
    
    const [claims] = await db.execute(query, [itemId]);
    res.json(claims);
  } catch (error) {
    console.error('Get claims error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Approve claim
app.post('/api/claims/:claimId/approve', async (req, res) => {
  try {
    const { claimId } = req.params;
    const { item_id } = req.body;
    
    // Update claim status to Approved
    await db.execute(
      'UPDATE claims SET status = ?, resolved_at = NOW() WHERE id = ?',
      ['Approved', claimId]
    );
    
    // Update item status to Resolved
    await db.execute(
      'UPDATE items SET status = ?, resolved_at = NOW() WHERE id = ?',
      ['Resolved', item_id]
    );
    
    // Get claimant info for notification
    const [claims] = await db.execute(
      'SELECT claimant_user_id FROM claims WHERE id = ?',
      [claimId]
    );
    
    if (claims.length > 0) {
      const claimantId = claims[0].claimant_user_id;
      
      // Create notification for claimant
      await db.execute(
        `INSERT INTO notifications (user_id, title, message, type, related_claim_id)
         VALUES (?, ?, ?, 'claim', ?)`,
        [
          claimantId,
          'Claim Approved!',
          'Your claim has been approved! Please contact the finder to collect your item.',
          claimId
        ]
      );
    }
    
    res.json({ success: true, message: 'Claim approved successfully' });
  } catch (error) {
    console.error('Approve claim error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Reject claim
app.post('/api/claims/:claimId/reject', async (req, res) => {
  try {
    const { claimId } = req.params;
    
    // Update claim status to Rejected
    await db.execute(
      'UPDATE claims SET status = ?, resolved_at = NOW() WHERE id = ?',
      ['Rejected', claimId]
    );
    
    // Get claimant info for notification
    const [claims] = await db.execute(
      'SELECT claimant_user_id FROM claims WHERE id = ?',
      [claimId]
    );
    
    if (claims.length > 0) {
      const claimantId = claims[0].claimant_user_id;
      
      // Create notification for claimant
      await db.execute(
        `INSERT INTO notifications (user_id, title, message, type, related_claim_id)
         VALUES (?, ?, ?, 'claim', ?)`,
        [
          claimantId,
          'Claim Rejected',
          'Unfortunately, your claim was not approved. Please try contacting the finder directly if you believe there was a mistake.',
          claimId
        ]
      );
    }
    
    res.json({ success: true, message: 'Claim rejected' });
  } catch (error) {
    console.error('Reject claim error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Mark item as resolved (manually by user)
app.post('/api/items/:itemId/resolve', async (req, res) => {
  try {
    const { itemId } = req.params;
    
    // Update item status to Resolved
    await db.execute(
      'UPDATE items SET status = ?, resolved_at = NOW() WHERE id = ?',
      ['Resolved', itemId]
    );
    
    res.json({ success: true, message: 'Item marked as resolved' });
  } catch (error) {
    console.error('Mark as resolved error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// ADMIN ROUTES
// ============================================

// Get all items (Admin only)
app.get('/api/admin/items', async (req, res) => {
  try {
    const query = `
      SELECT i.*, u.name as user_name, u.email as user_email,
             l.name as location_name
      FROM items i
      LEFT JOIN users u ON i.user_id = u.id
      LEFT JOIN locations l ON i.location_id = l.id
      ORDER BY i.created_at DESC
    `;
    
    const [items] = await db.execute(query);
    res.json(items);
  } catch (error) {
    console.error('Get all items error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all claims (Admin only)
app.get('/api/admin/claims', async (req, res) => {
  try {
    const query = `
      SELECT c.*, 
             u.name as claimant_name, u.email as claimant_email,
             i.title as item_title, i.type as item_type,
             owner.name as item_owner_name
      FROM claims c
      JOIN users u ON c.claimant_user_id = u.id
      JOIN items i ON c.item_id = i.id
      JOIN users owner ON i.user_id = owner.id
      ORDER BY c.created_at DESC
    `;
    
    const [claims] = await db.execute(query);
    res.json(claims);
  } catch (error) {
    console.error('Get all claims error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all users (Admin only)
app.get('/api/admin/users', async (req, res) => {
  try {
    const query = `
      SELECT id, name, ucid, email, role, phone, department, year, semester, 
             is_active, email_verified, created_at, last_login
      FROM users
      ORDER BY created_at DESC
    `;
    
    const [users] = await db.execute(query);
    res.json(users);
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get admin stats
app.get('/api/admin/stats', async (req, res) => {
  try {
    const [userCount] = await db.execute('SELECT COUNT(*) as count FROM users');
    const [itemCount] = await db.execute('SELECT COUNT(*) as count FROM items');
    const [lostCount] = await db.execute('SELECT COUNT(*) as count FROM items WHERE type = "Lost"');
    const [foundCount] = await db.execute('SELECT COUNT(*) as count FROM items WHERE type = "Found"');
    const [openCount] = await db.execute('SELECT COUNT(*) as count FROM items WHERE status = "Open"');
    const [claimCount] = await db.execute('SELECT COUNT(*) as count FROM claims WHERE status = "Pending"');
    const [resolvedCount] = await db.execute('SELECT COUNT(*) as count FROM items WHERE status = "Resolved"');
    
    res.json({
      users: userCount[0].count,
      items: itemCount[0].count,
      lostItems: lostCount[0].count,
      foundItems: foundCount[0].count,
      openItems: openCount[0].count,
      pendingClaims: claimCount[0].count,
      resolvedItems: resolvedCount[0].count
    });
  } catch (error) {
    console.error('Get admin stats error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// HTML ROUTES
// ============================================

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'home.html'));
});

app.get('/home', (req, res) => {
  res.sendFile(path.join(__dirname, 'home.html'));
});

app.get('/browse', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  console.log(`📊 Database: spit_lost_and_found (MySQL)`);
});