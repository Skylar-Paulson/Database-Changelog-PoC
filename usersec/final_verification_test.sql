-- Final verification test for release workflow
-- This verifies that PROD and QA releases are properly sorted

CREATE INDEX IF NOT EXISTS idx_final_verification ON users(username);
