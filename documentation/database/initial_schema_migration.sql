-- Migration: Initial HeyWish Database Schema
-- Description: Complete database schema for HeyWish application with all tables and relationships
-- Date: 2025-01-22
-- Target: Neon PostgreSQL Database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid text UNIQUE NOT NULL,
    email text UNIQUE,
    username text UNIQUE,
    full_name text,
    avatar_url text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create wishlists table
CREATE TABLE IF NOT EXISTS wishlists (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    visibility text NOT NULL CHECK (visibility IN ('public', 'friends', 'private')),
    cover_image_url text,
    share_token text UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create wishes table
CREATE TABLE IF NOT EXISTS wishes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    wishlist_id uuid NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    url text,
    price numeric,
    currency text,
    images text[],
    status text NOT NULL CHECK (status IN ('available', 'reserved', 'purchased')) DEFAULT 'available',
    priority integer,
    quantity integer NOT NULL DEFAULT 1,
    notes text,
    reserved_by uuid REFERENCES users(id),
    reserved_at timestamptz,
    purchased_at timestamptz,
    added_at timestamptz NOT NULL DEFAULT now()
);

-- Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
    user_id_1 uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_id_2 uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status text NOT NULL CHECK (status IN ('pending', 'accepted', 'blocked')) DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id_1, user_id_2),
    CONSTRAINT no_self_friendship CHECK (user_id_1 != user_id_2)
);

-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type text NOT NULL,
    data jsonb,
    timestamp timestamptz NOT NULL DEFAULT now()
);

-- Add table comments
COMMENT ON TABLE users IS 'User accounts synced from Firebase authentication';
COMMENT ON TABLE wishlists IS 'User-created wishlists with visibility controls';
COMMENT ON TABLE wishes IS 'Individual items within wishlists';
COMMENT ON TABLE friendships IS 'User friendship relationships and requests';
COMMENT ON TABLE activities IS 'Activity feed for user actions and events';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

CREATE INDEX IF NOT EXISTS idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_visibility ON wishlists(visibility);
CREATE INDEX IF NOT EXISTS idx_wishlists_share_token ON wishlists(share_token);

CREATE INDEX IF NOT EXISTS idx_wishes_wishlist_id ON wishes(wishlist_id);
CREATE INDEX IF NOT EXISTS idx_wishes_status ON wishes(status);
CREATE INDEX IF NOT EXISTS idx_wishes_reserved_by ON wishes(reserved_by);

CREATE INDEX IF NOT EXISTS idx_friendships_user_id_1 ON friendships(user_id_1);
CREATE INDEX IF NOT EXISTS idx_friendships_user_id_2 ON friendships(user_id_2);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);

CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_type ON activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_timestamp ON activities(timestamp);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wishlists_updated_at 
    BEFORE UPDATE ON wishlists 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'HeyWish database schema migration completed successfully!';
END $$;