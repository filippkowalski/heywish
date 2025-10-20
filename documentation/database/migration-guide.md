# Database Migration Guide for HeyWish

## Overview
This guide outlines best practices for creating and managing database migrations in the HeyWish project using PostgreSQL hosted on Render.com.

## Migration Naming Convention
- Format: `YYYYMMDDHHMMSS_description.sql`
- Example: `20250113120000_create_users_table.sql`
- Store in: `database/migrations/` directory

## Migration Structure Template
```sql
-- Migration: Create users table
-- Description: Initial user table for Firebase authentication integration
-- Date: 2025-01-13

-- Create users table
CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid text UNIQUE NOT NULL,
    email text,
    name text,
    username text UNIQUE,
    avatar_url text,
    sign_up_method text CHECK (sign_up_method IN ('email_password', 'google', 'apple', 'anonymous', 'phone')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Add comments
COMMENT ON TABLE users IS 'User accounts synced from Firebase authentication';

-- Create indexes
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (firebase_uid = auth.uid());

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (firebase_uid = auth.uid());
```

## Security Requirements
1. **Row Level Security (RLS)**: Enable on all tables
2. **Granular Policies**: Separate policies for each action (SELECT, INSERT, UPDATE, DELETE)
3. **Firebase Integration**: Use firebase_uid for user identification
4. **Role-based Access**: Different policies for authenticated vs anonymous users

## Best Practices
1. Always include descriptive comments
2. Create appropriate indexes for performance
3. Use proper data types (uuid, timestamptz, etc.)
4. Add constraints for data validation
5. Include rollback instructions in comments when needed

## Common Patterns

### User Authentication Table
- firebase_uid as unique identifier
- sign_up_method tracks registration method (email_password, google, apple, anonymous, phone)
- Email optional (for anonymous users)

### User-owned Resources
- Always include user_id foreign key
- RLS policies checking ownership
- Soft deletes with deleted_at timestamp

### Shared Resources
- Visibility levels (public, private, friends)
- Share tokens for public access
- Created by user tracking