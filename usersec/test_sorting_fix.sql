-- Test sorting fix with numeric prefixes
-- This should create releases with tags: 9-prod-DATE and 8-qa-DATE

CREATE INDEX IF NOT EXISTS idx_test_sorting ON users(email);
