-- Add shopping_interests column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS shopping_interests TEXT[] DEFAULT ARRAY[]::TEXT[];

-- Add comment
COMMENT ON COLUMN users.shopping_interests IS 'Array of shopping interest categories selected by user during onboarding';

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_shopping_interests ON users USING GIN (shopping_interests);