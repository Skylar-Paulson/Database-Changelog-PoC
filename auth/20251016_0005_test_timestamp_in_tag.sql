-- Test final tag format with timestamp
-- TEST-007: Verify tag format with full timestamp

CREATE TABLE IF NOT EXISTS test_timestamp_in_tag (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_note VARCHAR(255) DEFAULT 'Tag format: YYYY.MM.DD.HHMM-##',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tag: YYYY.MM.DD.HHMM-## (includes time, date handles rollover)
-- Name: {ENV} - YYYY.MM.DD.HHMM
-- Example: 2025.10.16.0000 > 2025.10.15.2359 (alphabetically)
