-- Test that counter continues incrementing
-- This should get prefix 3 when merged to qa

CREATE INDEX IF NOT EXISTS idx_counter_test ON users(updated_at);
