-- Migration: Add anonymous account support
-- Description: Remove share_token column and switch to username-based sharing
-- Date: 2025-03-30

-- Remove share_token column entirely (no longer needed)
ALTER TABLE wishlists
  DROP COLUMN IF EXISTS share_token;

-- Add index on username for fast profile lookups
CREATE INDEX IF NOT EXISTS idx_users_username_lookup ON users(username)
  WHERE username IS NOT NULL;

-- Migration complete
DO $$
BEGIN
    RAISE NOTICE 'Anonymous account support migration completed successfully!';
    RAISE NOTICE 'System now supports:';
    RAISE NOTICE '  - Anonymous users with auto-generated usernames (user1234567)';
    RAISE NOTICE '  - Username-based sharing (heywish.com/username)';
    RAISE NOTICE '  - Simplified account model';
    RAISE NOTICE '  - share_token column removed';
END $$;