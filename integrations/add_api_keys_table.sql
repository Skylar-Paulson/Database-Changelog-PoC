-- Add API keys table for API authentication
-- PROJ-1236: API key management

CREATE TABLE IF NOT EXISTS api_keys (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    key_name VARCHAR(255) NOT NULL,
    api_key VARCHAR(64) NOT NULL,
    secret_key VARCHAR(64) NOT NULL,
    permissions JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NULL,
    last_used_at DATETIME NULL,
    is_active TINYINT(1) DEFAULT 1,
    UNIQUE KEY uk_api_key (api_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_user_keys ON api_keys(user_id, is_active);
CREATE INDEX idx_api_key_lookup ON api_keys(api_key, is_active);
