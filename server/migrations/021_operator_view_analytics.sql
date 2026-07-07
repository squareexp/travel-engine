-- 021: Operator profile view & click-rate analytics counters
-- profile_views: incremented each time any traveller views the operator's public profile
-- click_rate:    rolling ratio (views → booking intent actions), stored as float (0.0–1.0)

ALTER TABLE operator_profiles
    ADD COLUMN IF NOT EXISTS profile_views  BIGINT  NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS click_count    BIGINT  NOT NULL DEFAULT 0;
