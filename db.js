// Database Connection for SPIT Lost & Found
// Uncomment when ready to use MySQL database

const mysql = require('mysql2');

// Database Configuration
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: 'mayuop',
  database: 'spit_lost_and_found',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// Create connection pool (better for production)
const pool = mysql.createPool(dbConfig);

// Get promise-based connection
const promisePool = pool.promise();

// Test connection
pool.getConnection((err, connection) => {
  if (err) {
    console.error('❌ Database connection failed:', err.message);
    console.log('\n📝 To setup database:');
    console.log('1. Make sure MySQL is running');
    console.log('2. Run: mysql -u root -p < database_schema.sql');
    console.log('3. Update db.js with correct credentials');
  } else {
    console.log('✅ Connected to MySQL database: spit_lost_and_found');
    connection.release();
  }
});

// Export both regular and promise pool
module.exports = {
  pool,
  promisePool,
  
  // Helper function to execute queries
  query: (sql, params) => {
    return new Promise((resolve, reject) => {
      pool.query(sql, params, (error, results) => {
        if (error) {
          reject(error);
        } else {
          resolve(results);
        }
      });
    });
  }
};

// Usage Examples:
// ----------------

// 1. Get all active lost items:
// const { query } = require('./db');
// const items = await query('SELECT * FROM v_active_lost_items');

// 2. Insert new user:
// const result = await query(
//   'INSERT INTO users (name, ucid, email, password, role) VALUES (?, ?, ?, ?, ?)',
//   [name, ucid, email, hashedPassword, role]
// );

// 3. Get user by email:
// const users = await query('SELECT * FROM users WHERE email = ?', [email]);

// 4. Update item status:
// await query('UPDATE items SET status = ? WHERE id = ?', ['Claimed', itemId]);
