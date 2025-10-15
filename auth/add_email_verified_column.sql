-- Add email verification status to users table
-- PROJ-1234: Email verification feature

CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100),
    email VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE users
ADD COLUMN email_verified TINYINT(1) DEFAULT 0 NOT NULL AFTER email,
ADD COLUMN verification_token VARCHAR(255) NULL,
ADD COLUMN token_expires_at DATETIME NULL;

CREATE INDEX idx_email_verified ON users(email_verified);
CREATE INDEX idx_verification_token ON users(verification_token);
