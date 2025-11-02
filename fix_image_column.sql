-- Fix image_url column size
USE spit_lost_and_found;

ALTER TABLE items MODIFY COLUMN image_url LONGTEXT;

-- Verify the change
DESCRIBE items;

