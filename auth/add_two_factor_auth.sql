-- Add two-factor authentication support
-- PROJ-2027: 2FA implementation

CREATE TABLE IF NOT EXISTS user_two_factor (
    two_factor_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    secret_key VARCHAR(255) NOT NULL,
    is_enabled TINYINT(1) DEFAULT 0,
    backup_codes JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    enabled_at DATETIME NULL,
    KEY idx_user_enabled (user_id, is_enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
