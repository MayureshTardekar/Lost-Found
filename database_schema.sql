-- ============================================
-- SPIT Lost & Found Database Schema
-- College Lost and Found Management System
-- ============================================

-- Create database
CREATE DATABASE IF NOT EXISTS spit_lost_and_found;
USE spit_lost_and_found;

-- ============================================
-- Table 1: Users (Students, Staff, Admin)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    ucid VARCHAR(10) UNIQUE NOT NULL COMMENT 'College ID - 10 digits',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT 'Must be @spit.ac.in',
    password VARCHAR(255) NOT NULL COMMENT 'Hashed password',
    role ENUM('student', 'staff', 'admin') DEFAULT 'student',
    phone VARCHAR(15),
    department VARCHAR(50) COMMENT 'MCA, CSE, IT, EXTC, etc.',
    year INT COMMENT 'Academic year for students (1-4)',
    semester INT COMMENT 'Current semester (1-8)',
    profile_image VARCHAR(500) COMMENT 'Profile picture URL/path',
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    
    INDEX idx_email (email),
    INDEX idx_ucid (ucid),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 2: Items (Lost/Found Items)
-- ============================================
CREATE TABLE IF NOT EXISTS items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'User who reported the item',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category ENUM(
        'Electronics',
        'Books',
        'Clothing',
        'Documents',
        'Accessories',
        'Bags',
        'ID Cards',
        'Keys',
        'Wallets',
        'Bottles',
        'Sports Equipment',
        'Stationery',
        'Other'
    ) NOT NULL DEFAULT 'Other',
    location VARCHAR(100) NOT NULL COMMENT 'Where lost/found',
    specific_location TEXT COMMENT 'Detailed location description',
    type ENUM('Lost', 'Found') NOT NULL,
    status ENUM('Open', 'Claimed', 'Resolved', 'Closed') DEFAULT 'Open',
    contact_info VARCHAR(255) NOT NULL,
    image_url VARCHAR(500) COMMENT 'Item image path',
    color VARCHAR(50),
    brand VARCHAR(100),
    found_date DATE COMMENT 'Date when lost/found',
    found_time TIME COMMENT 'Approximate time',
    reward_offered DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Reward amount if any',
    is_verified BOOLEAN DEFAULT FALSE COMMENT 'Verified by admin',
    views INT DEFAULT 0 COMMENT 'Number of views',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_category (category),
    INDEX idx_location (location),
    INDEX idx_created_at (created_at),
    FULLTEXT INDEX idx_search (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 3: Claims (When someone claims an item)
-- ============================================
CREATE TABLE IF NOT EXISTS claims (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL COMMENT 'Item being claimed',
    claimant_user_id INT NOT NULL COMMENT 'User claiming the item',
    message TEXT COMMENT 'Why they think it belongs to them',
    proof_image VARCHAR(500) COMMENT 'Proof of ownership image',
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    admin_notes TEXT COMMENT 'Admin verification notes',
    verified_by INT COMMENT 'Admin who verified',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    
    FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (claimant_user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_status (status),
    INDEX idx_item_id (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 4: Locations (Campus Locations)
-- ============================================
CREATE TABLE IF NOT EXISTS locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    building VARCHAR(50),
    floor VARCHAR(10),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 5: Notifications
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('claim', 'match', 'status_update', 'admin', 'general') DEFAULT 'general',
    related_item_id INT COMMENT 'Related item if applicable',
    related_claim_id INT COMMENT 'Related claim if applicable',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (related_item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (related_claim_id) REFERENCES claims(id) ON DELETE CASCADE,
    INDEX idx_user_read (user_id, is_read),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 6: Activity Log (Track all actions)
-- ============================================
CREATE TABLE IF NOT EXISTS activity_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL COMMENT 'login, logout, report_item, claim_item, etc.',
    entity_type VARCHAR(50) COMMENT 'item, claim, user',
    entity_id INT COMMENT 'ID of the entity affected',
    details TEXT COMMENT 'JSON or text description',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_action (user_id, action),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Insert Sample Locations
-- ============================================
INSERT INTO locations (name, building, floor, description) VALUES
('Library', 'Main Building', 'Ground', 'College Library'),
('Canteen', 'Main Building', 'Ground', 'Student Canteen'),
('Main Gate', 'Campus Entrance', NULL, 'Main entrance gate'),
('Parking Lot', 'Campus', NULL, 'Student/Staff parking area'),
('Classroom Block A', 'Academic Block A', 'All Floors', 'Classroom building A'),
('Classroom Block B', 'Academic Block B', 'All Floors', 'Classroom building B'),
('Computer Lab', 'Academic Block', '2nd Floor', 'Computer laboratory'),
('Admin Building', 'Administration', 'All Floors', 'Administrative offices'),
('Sports Complex', 'Sports Area', NULL, 'Sports facilities'),
('Auditorium', 'Main Building', '1st Floor', 'Main auditorium'),
('Staff Room', 'Academic Block', 'All Floors', 'Faculty staff rooms'),
('Hostel', 'Hostel Block', NULL, 'Student hostel area'),
('Ground Floor Corridor', 'Main Building', 'Ground', 'Ground floor corridors'),
('Staircase', 'All Buildings', 'All Floors', 'Building staircases'),
('Washroom Area', 'All Buildings', 'All Floors', 'Restroom areas');

-- ============================================
-- Insert Sample Admin User
-- ============================================
-- Password: admin123 (hashed with bcrypt - you'll need to update this)
INSERT INTO users (name, ucid, email, password, role, department, email_verified, is_active) VALUES
('Admin User', '0000000001', 'admin@spit.ac.in', '$2a$10$YourHashedPasswordHere', 'admin', 'Administration', TRUE, TRUE);

-- ============================================
-- Insert Sample Test Users
-- ============================================
-- Password: test123 (hashed with bcrypt - you'll need to update this)
INSERT INTO users (name, ucid, email, password, role, department, year, semester, email_verified, is_active) VALUES
('Test Student', '2021001001', 'test.student@spit.ac.in', '$2a$10$YourHashedPasswordHere', 'student', 'MCA', 2, 3, TRUE, TRUE),
('John Doe', '2021001002', 'john.doe@spit.ac.in', '$2a$10$YourHashedPasswordHere', 'student', 'CSE', 3, 5, TRUE, TRUE),
('Jane Smith', '2021001003', 'jane.smith@spit.ac.in', '$2a$10$YourHashedPasswordHere', 'student', 'IT', 2, 4, TRUE, TRUE);

-- ============================================
-- Insert Sample Items (for testing)
-- ============================================
INSERT INTO items (user_id, title, description, category, location, type, status, contact_info, found_date, is_verified) VALUES
(2, 'Black Leather Wallet', 'Lost black leather wallet with multiple cards inside. Last seen near the library entrance.', 'Wallets', 'Library', 'Lost', 'Open', 'test.student@spit.ac.in', CURDATE(), TRUE),
(3, 'Found ID Card', 'Found a student ID card near the canteen. Name starts with R. Contact to claim with proof.', 'ID Cards', 'Canteen', 'Found', 'Open', 'john.doe@spit.ac.in', CURDATE() - INTERVAL 1 DAY, TRUE),
(4, 'Blue Water Bottle', 'Lost my blue Cello water bottle in the sports complex during basketball practice.', 'Bottles', 'Sports Complex', 'Lost', 'Open', 'jane.smith@spit.ac.in', CURDATE() - INTERVAL 2 DAY, TRUE),
(2, 'Set of Keys', 'Found a keychain with 4 keys near parking lot. Has a red keychain with initials.', 'Keys', 'Parking Lot', 'Found', 'Open', 'test.student@spit.ac.in', CURDATE() - INTERVAL 3 DAY, TRUE),
(3, 'Data Structures Book', 'Lost my Data Structures textbook in Classroom Block A. Has my name written inside.', 'Books', 'Classroom Block A', 'Lost', 'Open', 'john.doe@spit.ac.in', CURDATE() - INTERVAL 5 DAY, TRUE);

-- ============================================
-- Useful Views
-- ============================================

-- View: Active Lost Items
CREATE OR REPLACE VIEW v_active_lost_items AS
SELECT 
    i.*,
    u.name as reporter_name,
    u.email as reporter_email,
    u.phone as reporter_phone
FROM items i
JOIN users u ON i.user_id = u.id
WHERE i.type = 'Lost' AND i.status = 'Open'
ORDER BY i.created_at DESC;

-- View: Active Found Items
CREATE OR REPLACE VIEW v_active_found_items AS
SELECT 
    i.*,
    u.name as reporter_name,
    u.email as reporter_email,
    u.phone as reporter_phone
FROM items i
JOIN users u ON i.user_id = u.id
WHERE i.type = 'Found' AND i.status = 'Open'
ORDER BY i.created_at DESC;

-- View: Pending Claims
CREATE OR REPLACE VIEW v_pending_claims AS
SELECT 
    c.*,
    i.title as item_title,
    i.type as item_type,
    u1.name as claimant_name,
    u1.email as claimant_email,
    u2.name as item_reporter_name
FROM claims c
JOIN items i ON c.item_id = i.id
JOIN users u1 ON c.claimant_user_id = u1.id
JOIN users u2 ON i.user_id = u2.id
WHERE c.status = 'Pending'
ORDER BY c.created_at ASC;

-- ============================================
-- Stored Procedures
-- ============================================

-- Procedure: Mark item as claimed
DELIMITER //
CREATE PROCEDURE mark_item_claimed(
    IN p_item_id INT,
    IN p_claim_id INT
)
BEGIN
    UPDATE items 
    SET status = 'Claimed', 
        resolved_at = NOW()
    WHERE id = p_item_id;
    
    UPDATE claims 
    SET status = 'Approved',
        resolved_at = NOW()
    WHERE id = p_claim_id;
END //
DELIMITER ;

-- Procedure: Get item statistics
DELIMITER //
CREATE PROCEDURE get_item_statistics()
BEGIN
    SELECT 
        COUNT(*) as total_items,
        SUM(CASE WHEN type = 'Lost' THEN 1 ELSE 0 END) as total_lost,
        SUM(CASE WHEN type = 'Found' THEN 1 ELSE 0 END) as total_found,
        SUM(CASE WHEN status = 'Open' THEN 1 ELSE 0 END) as active_items,
        SUM(CASE WHEN status = 'Claimed' OR status = 'Resolved' THEN 1 ELSE 0 END) as resolved_items,
        COUNT(DISTINCT user_id) as total_reporters
    FROM items;
END //
DELIMITER ;

-- ============================================
-- Triggers
-- ============================================

-- Trigger: Update item views count
DELIMITER //
CREATE TRIGGER update_item_views
AFTER INSERT ON activity_log
FOR EACH ROW
BEGIN
    IF NEW.action = 'view_item' AND NEW.entity_type = 'item' THEN
        UPDATE items SET views = views + 1 WHERE id = NEW.entity_id;
    END IF;
END //
DELIMITER ;

-- Trigger: Create notification on new claim
DELIMITER //
CREATE TRIGGER notify_on_new_claim
AFTER INSERT ON claims
FOR EACH ROW
BEGIN
    DECLARE item_owner_id INT;
    
    SELECT user_id INTO item_owner_id FROM items WHERE id = NEW.item_id;
    
    INSERT INTO notifications (user_id, title, message, type, related_item_id, related_claim_id)
    VALUES (
        item_owner_id,
        'New Claim on Your Item',
        'Someone has claimed your item. Please review the claim.',
        'claim',
        NEW.item_id,
        NEW.id
    );
END //
DELIMITER ;

DELIMITER ;

-- ============================================
-- Indexes for Performance
-- ============================================
-- (Already created in table definitions above)

-- ============================================
-- Database Setup Complete!
-- ============================================

-- To use this database:
-- 1. Run: mysql -u root -p < database_schema.sql
-- 2. Update password hashes for sample users using bcrypt
-- 3. Configure db.js with correct credentials
-- 4. Test the connection

-- Note: Remember to update the hashed passwords!
-- Use bcryptjs in Node.js to generate proper password hashes

