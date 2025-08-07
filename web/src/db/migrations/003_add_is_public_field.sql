-- Add is_public field for easier querying
ALTER TABLE wishlists
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false;

-- Update is_public based on visibility
UPDATE wishlists
SET is_public = CASE 
    WHEN visibility = 'public' THEN true
    ELSE false
END;

-- Add index for public wishlists
CREATE INDEX IF NOT EXISTS idx_wishlists_is_public ON wishlists(is_public) WHERE is_public = true;

-- Add trigger to keep is_public in sync with visibility
CREATE OR REPLACE FUNCTION update_is_public()
RETURNS TRIGGER AS $$
BEGIN
    NEW.is_public = (NEW.visibility = 'public');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_is_public
BEFORE INSERT OR UPDATE OF visibility ON wishlists
FOR EACH ROW
EXECUTE FUNCTION update_is_public();