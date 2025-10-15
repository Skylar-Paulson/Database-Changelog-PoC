-- Add feature flags table for dynamic feature management
-- PROJ-2025: Feature flag system implementation

CREATE TABLE IF NOT EXISTS feature_flags (
    flag_id INT PRIMARY KEY AUTO_INCREMENT,
    flag_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    enabled TINYINT(1) DEFAULT 0 NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    KEY idx_flag_name (flag_name),
    KEY idx_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
