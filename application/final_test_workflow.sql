-- Final test of complete workflow after history cleanup
-- Testing incremental counter and chronological sorting

CREATE TABLE IF NOT EXISTS workflow_test (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
