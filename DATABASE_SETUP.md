# 🗄️ Database Setup Guide

## 📋 Tables Overview

Your Lost & Found system uses **6 main tables**:

| Table | Purpose | Records |
|-------|---------|---------|
| 👤 **users** | Students, Staff, Admin | User accounts |
| 📦 **items** | Lost/Found Items | All reported items |
| 🤝 **claims** | Item Claims | When someone claims an item |
| 📍 **locations** | Campus Locations | Predefined locations |
| 🔔 **notifications** | User Notifications | System notifications |
| 📊 **activity_log** | Activity Tracking | Audit trail |

---

## 🚀 Quick Setup

### **Step 1: Install MySQL**

If not installed:
- Download from: https://dev.mysql.com/downloads/mysql/
- Or use XAMPP/WAMP which includes MySQL

### **Step 2: Start MySQL Server**

**Using XAMPP:**
```bash
# Open XAMPP Control Panel
# Click "Start" for MySQL
```

**Using Command Line:**
```bash
# Windows
net start MySQL80

# Linux/Mac
sudo service mysql start
```

### **Step 3: Create Database**

**Method A: Using Command Line**
```bash
# Navigate to project folder
cd "C:\Users\MAYURESH\Desktop\MCA\Lost&Found\L&F"

# Run the schema file
mysql -u root -p < database_schema.sql
# Enter your MySQL password when prompted
```

**Method B: Using phpMyAdmin**
1. Open: http://localhost/phpmyadmin
2. Click "Import" tab
3. Choose file: `database_schema.sql`
4. Click "Go"

**Method C: Using MySQL Workbench**
1. Open MySQL Workbench
2. Connect to your server
3. File → Open SQL Script → Select `database_schema.sql`
4. Execute (⚡ button)

### **Step 4: Update Database Credentials**

Edit `db.js`:
```javascript
const dbConfig = {
  host: 'localhost',
  user: 'root',           // Your MySQL username
  password: 'your_password', // Your MySQL password
  database: 'spit_lost_and_found',
  // ...
};
```

### **Step 5: Test Connection**

```bash
node -e "require('./db')"
```

You should see:
```
✅ Connected to MySQL database: spit_lost_and_found
```

---

## 📊 Database Structure Details

### **1. users Table**
Stores all user information (students, staff, admins)

**Key Fields:**
- `ucid` - College ID (10 digits, unique)
- `email` - Must be @spit.ac.in
- `password` - Bcrypt hashed
- `role` - student | staff | admin
- `department` - MCA, CSE, IT, etc.

**Sample Query:**
```sql
-- Get all students from MCA department
SELECT * FROM users 
WHERE role = 'student' AND department = 'MCA';
```

### **2. items Table**
All lost and found items

**Key Fields:**
- `type` - Lost | Found
- `status` - Open | Claimed | Resolved | Closed
- `category` - Electronics, Books, Clothing, etc.
- `location` - Where item was lost/found

**Sample Query:**
```sql
-- Get all open lost items
SELECT * FROM items 
WHERE type = 'Lost' AND status = 'Open'
ORDER BY created_at DESC;
```

### **3. claims Table**
When someone claims an item

**Key Fields:**
- `item_id` - Which item is being claimed
- `claimant_user_id` - Who is claiming
- `status` - Pending | Approved | Rejected
- `proof_image` - Proof of ownership

**Sample Query:**
```sql
-- Get pending claims with item details
SELECT c.*, i.title, u.name as claimant_name
FROM claims c
JOIN items i ON c.item_id = i.id
JOIN users u ON c.claimant_user_id = u.id
WHERE c.status = 'Pending';
```

### **4. locations Table**
Predefined campus locations

**Pre-populated with:**
- Library
- Canteen
- Main Gate
- Parking Lot
- Classroom Blocks
- Computer Lab
- Sports Complex
- And more...

### **5. notifications Table**
System notifications for users

**Types:**
- New claim on your item
- Claim approved/rejected
- Item matched
- Admin messages

### **6. activity_log Table**
Tracks all user actions for security and analytics

---

## 🔐 Security Features

### **Password Hashing**
Passwords are hashed using bcrypt:

```javascript
const bcrypt = require('bcryptjs');

// Hash password
const hashedPassword = await bcrypt.hash('password123', 10);

// Verify password
const isValid = await bcrypt.compare('password123', hashedPassword);
```

### **Update Sample User Passwords**

After database creation, update passwords:

```sql
-- Use Node.js to generate hash first
-- node -e "const bcrypt = require('bcryptjs'); console.log(bcrypt.hashSync('admin123', 10));"

UPDATE users 
SET password = '$2a$10$YourGeneratedHashHere'
WHERE email = 'admin@spit.ac.in';
```

---

## 📈 Useful Queries

### **Statistics**
```sql
-- Call stored procedure for statistics
CALL get_item_statistics();

-- Manual statistics query
SELECT 
    COUNT(*) as total_items,
    SUM(CASE WHEN type = 'Lost' THEN 1 ELSE 0 END) as lost_items,
    SUM(CASE WHEN type = 'Found' THEN 1 ELSE 0 END) as found_items,
    SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) as resolved_items
FROM items;
```

### **Recent Activity**
```sql
-- Last 10 reported items
SELECT i.*, u.name as reporter_name
FROM items i
JOIN users u ON i.user_id = u.id
ORDER BY i.created_at DESC
LIMIT 10;
```

### **Popular Locations**
```sql
-- Most common locations for lost items
SELECT location, COUNT(*) as count
FROM items
WHERE type = 'Lost'
GROUP BY location
ORDER BY count DESC
LIMIT 5;
```

### **Active Users**
```sql
-- Users with most reports
SELECT u.name, u.email, COUNT(i.id) as total_reports
FROM users u
LEFT JOIN items i ON u.id = i.user_id
GROUP BY u.id
ORDER BY total_reports DESC
LIMIT 10;
```

---

## 🔄 Switching from localStorage to MySQL

### **Current (localStorage):**
```javascript
// Get posts
const posts = JSON.parse(localStorage.getItem('campus_lost_found_posts'));
```

### **Future (MySQL):**
```javascript
// Get posts
const { query } = require('./db');
const posts = await query('SELECT * FROM items ORDER BY created_at DESC');
```

### **Migration Steps:**

1. **Enable Database Connection** (Uncomment in `server.js`)
2. **Create API Routes**
3. **Replace localStorage Calls**
4. **Add Error Handling**
5. **Test Thoroughly**

---

## 🛠️ Maintenance

### **Backup Database**
```bash
mysqldump -u root -p spit_lost_and_found > backup_$(date +%Y%m%d).sql
```

### **Restore Database**
```bash
mysql -u root -p spit_lost_and_found < backup_20250127.sql
```

### **Clear Old Data**
```sql
-- Delete resolved items older than 6 months
DELETE FROM items 
WHERE status IN ('Resolved', 'Closed') 
AND resolved_at < DATE_SUB(NOW(), INTERVAL 6 MONTH);
```

---

## ⚠️ Troubleshooting

### **Error: Cannot connect to MySQL**
```bash
# Check if MySQL is running
mysqladmin -u root -p status

# Restart MySQL
net stop MySQL80
net start MySQL80
```

### **Error: Access denied**
```bash
# Reset root password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

### **Error: Database doesn't exist**
```sql
-- Manually create database
CREATE DATABASE spit_lost_and_found;
USE spit_lost_and_found;
-- Then run schema file
```

---

## 📚 Additional Resources

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Node.js MySQL2](https://github.com/sidorares/node-mysql2)
- [bcryptjs](https://www.npmjs.com/package/bcryptjs)

---

## ✅ Checklist

Before going live with database:

- [ ] MySQL installed and running
- [ ] Database created using schema file
- [ ] Sample data loaded successfully
- [ ] User passwords updated with bcrypt hashes
- [ ] `db.js` credentials configured
- [ ] Connection test successful
- [ ] Backup strategy in place
- [ ] API routes created
- [ ] Error handling implemented
- [ ] Security measures reviewed

---

**Need Help?** Check the error logs or contact the database admin.

