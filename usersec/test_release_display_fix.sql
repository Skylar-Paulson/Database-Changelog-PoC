-- Test fix for release visibility issue
-- This should create releases without target_commitish parameter

CREATE INDEX IF NOT EXISTS idx_test_display_fix ON users(last_updated);
