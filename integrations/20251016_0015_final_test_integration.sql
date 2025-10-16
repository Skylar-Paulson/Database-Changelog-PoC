-- Final workflow test - integrations schema
-- TEST-009: Verify multiple commits in workflow

CREATE TABLE IF NOT EXISTS webhook_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    service_name VARCHAR(100) NOT NULL,
    endpoint_url VARCHAR(500) NOT NULL,
    request_payload TEXT,
    response_payload TEXT,
    status_code INT,
    response_time_ms INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_service_name (service_name),
    INDEX idx_status_code (status_code),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
