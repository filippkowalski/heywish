-- Add reservation tracking fields to wishes table
ALTER TABLE wishes
ADD COLUMN IF NOT EXISTS reserver_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS reserver_email VARCHAR(255),
ADD COLUMN IF NOT EXISTS reserved_at TIMESTAMP WITH TIME ZONE;

-- Add index for faster public wishlist lookups
CREATE INDEX IF NOT EXISTS idx_wishlists_share_token ON wishlists(share_token) WHERE is_public = true;

-- Add index for reserved items
CREATE INDEX IF NOT EXISTS idx_wishes_reserved ON wishes(wishlist_id, reserved_by) WHERE reserved_by IS NOT NULL;