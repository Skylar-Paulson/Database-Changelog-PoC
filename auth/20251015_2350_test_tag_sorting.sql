-- Test new tag format
-- TEST-005: Verify tag sorting fix

CREATE TABLE IF NOT EXISTS test_tag_sorting (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_note VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- This file tests the new tag format: YYYY.MM.DD.HHMM-##
-- which should sort newest-first alphabetically
