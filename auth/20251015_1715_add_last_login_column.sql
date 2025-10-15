-- Add last login tracking to users table
-- PROJ-1240: Track user login activity

CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE users
ADD COLUMN last_login_at DATETIME NULL,
ADD COLUMN last_login_ip VARCHAR(45) NULL;

CREATE INDEX idx_users_last_login ON users(last_login_at);
