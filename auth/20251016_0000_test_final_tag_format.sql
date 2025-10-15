-- Test final tag format without time in tag
-- TEST-006: Verify tag format works across midnight rollover

CREATE TABLE IF NOT EXISTS test_final_tag_format (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_note VARCHAR(255) DEFAULT 'Final tag format: YYYY.MM.DD-##',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tag: YYYY.MM.DD-## (no time, incrementing number handles sorting)
-- Name: {ENV} - YYYY.MM.DD.HHMM (includes time for display)
