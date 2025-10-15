-- Test incremental counter for release sorting
-- This should create releases with sequential numbers (1, 2, 3, etc.)

CREATE INDEX IF NOT EXISTS idx_incremental_test ON users(created_at);
