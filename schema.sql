-- Commented out all schema code for client-side conversion
-- -- Create database
-- CREATE DATABASE IF NOT EXISTS lost_and_found;
-- USE lost_and_found;

-- -- Users table
-- CREATE TABLE IF NOT EXISTS users (
--   id INT AUTO_INCREMENT PRIMARY KEY,
--   name VARCHAR(100) NOT NULL,
--   email VARCHAR(100) UNIQUE NOT NULL,
--   password VARCHAR(255) NOT NULL,
--   role ENUM('user', 'admin') DEFAULT 'user',
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Items table
-- CREATE TABLE IF NOT EXISTS items (
--   id INT AUTO_INCREMENT PRIMARY KEY,
--   title VARCHAR(255) NOT NULL,
--   description TEXT,
--   category VARCHAR(50),
--   location VARCHAR(100),
--   status ENUM('lost', 'found') NOT NULL,
--   contact_info VARCHAR(255),
--   image_url VARCHAR(500),
--   user_id INT,
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
-- );

-- -- Insert sample data
-- INSERT INTO users (name, email, password, role) VALUES
-- ('Admin', 'admin@spit.ac.in', '$2a$10$examplehashedpassword', 'admin'),
-- ('John Doe', 'john@spit.ac.in', '$2a$10$examplehashedpassword', 'user');

-- INSERT INTO items (title, description, category, location, status, contact_info, user_id) VALUES
-- ('Lost Wallet', 'Black leather wallet with ID cards', 'Electronics', 'Library', 'lost', 'john@spit.ac.in', 2),
-- ('Found Keys', 'Set of keys found near parking lot', 'Other', 'Parking Lot', 'found', 'admin@spit.ac.in', 1);
