ALTER TABLE spit_lost_and_found.items 
MODIFY COLUMN image_url LONGTEXT;
DESCRIBE items;
-- ============================================
-- SPIT Lost & Found Database Schema v2.0 (FIXED)
-- ============================================

CREATE DATABASE IF NOT EXISTS spit_lost_and_found;
USE spit_lost_and_found;
USE spit_lost_and_found;
DESCRIBE items;
ALTER TABLE items 
CHANGE COLUMN image_url image_url LONGTEXT;
-- ============================================
-- Table 1: Users
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    ucid VARCHAR(10) UNIQUE NOT NULL COMMENT 'College ID - 10 digits',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT 'Must be @spit.ac.in',
    password VARCHAR(255) NOT NULL COMMENT 'Hashed password using bcrypt',
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
    INDEX idx_role (role),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 2: Locations (MOVED BEFORE ITEMS!) ⭐
-- ============================================
CREATE TABLE IF NOT EXISTS locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    building VARCHAR(50),
    floor VARCHAR(10),
    description TEXT,
    coordinates POINT COMMENT 'GPS coordinates',
    is_active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_active (is_active),
    INDEX idx_order (display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 3: Items (NOW locations exists!)
-- ============================================
CREATE TABLE IF NOT EXISTS items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'User who reported',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category ENUM(
        'Electronics', 'Books', 'Clothing', 'Documents',
        'Accessories', 'ID Cards', 'Keys', 'Wallets',
        'Bags', 'Bottles', 'Sports Equipment', 'Stationery', 'Other'
    ) NOT NULL DEFAULT 'Other',
    location_id INT COMMENT 'References locations table',
    location_text VARCHAR(100) COMMENT 'Free-form location',
    type ENUM('Lost', 'Found') NOT NULL,
    status ENUM('Open', 'Matched', 'Claimed', 'Resolved', 'Closed') DEFAULT 'Open',
    contact_info VARCHAR(255) NOT NULL,
    image_url VARCHAR(500),
    color VARCHAR(50),
    brand VARCHAR(100),
    found_date DATE,
    found_time TIME,
    reward_offered DECIMAL(10, 2) DEFAULT 0.00,
    is_verified BOOLEAN DEFAULT FALSE,
    views INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_category (category),
    INDEX idx_location_id (location_id),
    INDEX idx_created_at (created_at),
    INDEX idx_type_status (type, status),
    FULLTEXT INDEX idx_search (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 4: Claims
-- ============================================
CREATE TABLE IF NOT EXISTS claims (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    claimant_user_id INT NOT NULL,
    message TEXT,
    proof_image VARCHAR(500),
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    admin_notes TEXT,
    verified_by INT,
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
-- Table 5: Matches
-- ============================================
CREATE TABLE IF NOT EXISTS matches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lost_item_id INT NOT NULL,
    found_item_id INT NOT NULL,
    match_score DECIMAL(5,2) NOT NULL,
    match_reason JSON,
    status ENUM('Pending', 'Confirmed', 'Rejected', 'Expired') DEFAULT 'Pending',
    created_by_admin BOOLEAN DEFAULT FALSE,
    created_by_user_id INT,
    admin_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    
    FOREIGN KEY (lost_item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (found_item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_match (lost_item_id, found_item_id),
    INDEX idx_status (status),
    INDEX idx_score (match_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 6: Notifications
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('claim', 'match', 'status_update', 'admin', 'general') DEFAULT 'general',
    priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
    related_item_id INT,
    related_claim_id INT,
    related_match_id INT,
    action_url VARCHAR(500),
    is_read BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (related_item_id) REFERENCES items(id) ON DELETE CASCADE,
    FOREIGN KEY (related_claim_id) REFERENCES claims(id) ON DELETE CASCADE,
    FOREIGN KEY (related_match_id) REFERENCES matches(id) ON DELETE CASCADE,
    INDEX idx_user_read (user_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table 7: Admin Actions
-- ============================================
CREATE TABLE IF NOT EXISTS admin_actions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    admin_id INT NOT NULL,
    action_type ENUM(
        'approve_claim', 'reject_claim', 'verify_item', 'delete_item',
        'create_match', 'confirm_match', 'reject_match',
        'ban_user', 'unban_user', 'delete_user', 'edit_item',
        'change_status', 'other'
    ) NOT NULL,
    target_type ENUM('item', 'claim', 'user', 'match', 'notification') NOT NULL,
    target_id INT NOT NULL,
    before_data JSON,
    after_data JSON,
    details TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_admin_action (admin_id, action_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Insert Sample Locations
-- ============================================
INSERT INTO locations (name, building, floor, description, display_order) VALUES
('Library', 'Main Building', 'Ground', 'College Library', 1),
('Canteen', 'Main Building', 'Ground', 'Student Canteen', 2),
('Main Gate', 'Campus Entrance', NULL, 'Main entrance gate', 3),
('Parking Lot', 'Campus', NULL, 'Parking area', 4),
('Classroom Block A', 'Academic Block A', 'All', 'Classrooms 101-510', 5),
('Classroom Block B', 'Academic Block B', 'All', 'Classrooms 101-510', 6),
('Computer Lab', 'Academic Block', '2nd', 'Computer lab', 7),
('Admin Building', 'Administration', 'All', 'Admin offices', 8),
('Sports Complex', 'Sports Area', NULL, 'Sports facilities', 9),
('Auditorium', 'Main Building', '1st', 'Main auditorium', 10);

-- ============================================
-- Insert Sample Admin User
-- ============================================
INSERT INTO users (name, ucid, email, password, role, department, email_verified, is_active) VALUES
('Admin', '0000000001', 'admin@spit.ac.in', '$2a$10$examplehash', 'admin', 'Admin', TRUE, TRUE);

-- ============================================
-- Success!
-- ============================================
SELECT 'Database setup complete!' as Status;
