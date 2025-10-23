-- Baseline schema for Jinnie
-- Generated on 2025-10-23

SET search_path = public;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid text UNIQUE NOT NULL,
    email text,
    email_verified boolean NOT NULL DEFAULT false,
    username text UNIQUE,
    full_name text,
    avatar_url text,
    bio text,
    location text,
    birthdate date,
    interests text[],
    shopping_interests text[] DEFAULT ARRAY[]::text[],
    gender varchar(20),
    phone_number varchar(20),
    phone_verified boolean NOT NULL DEFAULT false,
    notification_preferences jsonb NOT NULL DEFAULT '{
        "birthday_notifications": true,
        "coupon_notifications": true,
        "discount_notifications": true,
        "friend_activity": true,
        "wishlist_updates": true
    }'::jsonb,
    privacy_settings jsonb NOT NULL DEFAULT '{
        "phone_discoverable": false,
        "show_birthday": true,
        "show_gender": false
    }'::jsonb,
    sign_up_method text,
    is_profile_public boolean NOT NULL DEFAULT true,
    fcm_token text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    last_seen timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_sign_up_method ON users(sign_up_method);
CREATE INDEX idx_users_shopping_interests ON users USING GIN (shopping_interests);

-- Wishlists table
CREATE TABLE wishlists (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    visibility text NOT NULL DEFAULT 'private' CHECK (visibility IN ('private', 'friends', 'public')),
    wishlist_type text NOT NULL DEFAULT 'personal' CHECK (wishlist_type IN ('personal', 'kids', 'registry', 'holiday', 'event', 'other')),
    slug text,
    cover_image_url text,
    share_token text UNIQUE,
    share_password text,
    share_expires_at timestamptz,
    item_count integer NOT NULL DEFAULT 0,
    reserved_count integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_wishlists_user_id ON wishlists(user_id);
CREATE INDEX idx_wishlists_slug ON wishlists(slug);
CREATE INDEX idx_wishlists_share_token ON wishlists(share_token);
CREATE INDEX idx_wishlists_visibility ON wishlists(visibility);
CREATE INDEX idx_wishlists_created_at ON wishlists(created_at);

-- Wishes table
CREATE TABLE wishes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    wishlist_id uuid REFERENCES wishlists(id) ON DELETE CASCADE,
    created_by uuid REFERENCES users(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    url text,
    price numeric(10, 2),
    currency text NOT NULL DEFAULT 'USD',
    images text[],
    status text NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'purchased')),
    priority integer NOT NULL DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
    quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
    notes text,
    reserved_by uuid REFERENCES users(id) ON DELETE SET NULL,
    reserved_at timestamptz,
    reserved_message text,
    position integer NOT NULL DEFAULT 0,
    source text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'share_extension', 'import', 'ai_assist')),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_wishes_wishlist_id ON wishes(wishlist_id);
CREATE INDEX idx_wishes_created_by ON wishes(created_by);
CREATE INDEX idx_wishes_status ON wishes(status);
CREATE INDEX idx_wishes_reserved_by ON wishes(reserved_by);
CREATE INDEX idx_wishes_created_at ON wishes(created_at);
CREATE INDEX idx_wishes_uncategorized ON wishes(id) WHERE wishlist_id IS NULL;

-- Friendships table
CREATE TABLE friendships (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (requester_id, addressee_id),
    CHECK (requester_id <> addressee_id)
);

CREATE INDEX idx_friendships_requester_id ON friendships(requester_id);
CREATE INDEX idx_friendships_addressee_id ON friendships(addressee_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- Activities table
CREATE TABLE activities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type text NOT NULL CHECK (activity_type IN ('collection_created', 'item_added', 'item_reserved', 'item_purchased', 'friend_added')),
    data jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_activities_user_id ON activities(user_id);
CREATE INDEX idx_activities_type ON activities(activity_type);
CREATE INDEX idx_activities_created_at ON activities(created_at);

-- Wishlist tags table
CREATE TABLE wishlist_tags (
    wishlist_id uuid NOT NULL REFERENCES wishlists(id) ON DELETE CASCADE,
    tag text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (wishlist_id, tag)
);

CREATE INDEX idx_wishlist_tags_tag ON wishlist_tags(tag);

-- Wish variants table
CREATE TABLE wish_variants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    wish_id uuid NOT NULL REFERENCES wishes(id) ON DELETE CASCADE,
    label text NOT NULL,
    value text NOT NULL,
    is_default boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_wish_variants_wish_id ON wish_variants(wish_id);

-- Wish price history table
CREATE TABLE wish_price_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    wish_id uuid NOT NULL REFERENCES wishes(id) ON DELETE CASCADE,
    price numeric(10, 2),
    currency text NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT now(),
    source text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'sync', 'import', 'scraper'))
);

CREATE INDEX idx_wish_price_history_wish_id ON wish_price_history(wish_id);

-- Utility functions and triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_wishlist_counters()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE wishlists 
        SET item_count = item_count + 1,
            reserved_count = reserved_count + CASE WHEN NEW.status = 'reserved' THEN 1 ELSE 0 END
        WHERE id = NEW.wishlist_id;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status <> NEW.status THEN
            UPDATE wishlists
            SET reserved_count = reserved_count
                + CASE WHEN NEW.status = 'reserved' THEN 1 ELSE 0 END
                - CASE WHEN OLD.status = 'reserved' THEN 1 ELSE 0 END
            WHERE id = NEW.wishlist_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE wishlists
        SET item_count = item_count - 1,
            reserved_count = reserved_count - CASE WHEN OLD.status = 'reserved' THEN 1 ELSE 0 END
        WHERE id = OLD.wishlist_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wishlists_updated_at
    BEFORE UPDATE ON wishlists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wishes_updated_at
    BEFORE UPDATE ON wishes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friendships_updated_at
    BEFORE UPDATE ON friendships
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wishlist_counters_trigger
    AFTER INSERT OR UPDATE OR DELETE ON wishes
    FOR EACH ROW EXECUTE FUNCTION update_wishlist_counters();

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

-- RLS policies for users
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (firebase_uid = current_setting('app.current_user_uid', true));

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (firebase_uid = current_setting('app.current_user_uid', true));

CREATE POLICY "Allow user creation during sync" ON users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow user updates during sync" ON users
    FOR UPDATE USING (true);

-- RLS policies for wishlists
CREATE POLICY "Users can view own wishlists" ON wishlists
    FOR SELECT USING (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)));

CREATE POLICY "Users can view public wishlists" ON wishlists
    FOR SELECT USING (visibility = 'public');

CREATE POLICY "Users can create wishlists" ON wishlists
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)));

CREATE POLICY "Users can update own wishlists" ON wishlists
    FOR UPDATE USING (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)));

CREATE POLICY "Users can delete own wishlists" ON wishlists
    FOR DELETE USING (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)));

-- RLS policies for wishes
CREATE POLICY "Users can view their own wishes" ON wishes
    FOR SELECT USING (
        -- Own wishes in wishlists
        wishlist_id IN (
            SELECT id FROM wishlists
            WHERE user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
        )
        -- Own uncategorized wishes
        OR (wishlist_id IS NULL AND created_by = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)))
        -- Public wishlist wishes
        OR wishlist_id IN (SELECT id FROM wishlists WHERE visibility = 'public')
    );

CREATE POLICY "Users can create wishes" ON wishes
    FOR INSERT WITH CHECK (
        -- In own wishlists
        (wishlist_id IS NOT NULL AND wishlist_id IN (
            SELECT id FROM wishlists
            WHERE user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
        ))
        -- As uncategorized
        OR (wishlist_id IS NULL AND created_by = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)))
    );

CREATE POLICY "Users can update their wishes" ON wishes
    FOR UPDATE USING (
        -- Own wishes in wishlists
        wishlist_id IN (
            SELECT id FROM wishlists
            WHERE user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
        )
        -- Own uncategorized wishes
        OR (wishlist_id IS NULL AND created_by = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)))
    );

CREATE POLICY "Users can delete their wishes" ON wishes
    FOR DELETE USING (
        -- Own wishes in wishlists
        wishlist_id IN (
            SELECT id FROM wishlists
            WHERE user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
        )
        -- Own uncategorized wishes
        OR (wishlist_id IS NULL AND created_by = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)))
    );

-- RLS policies for friendships
CREATE POLICY "Users can view their friendships" ON friendships
    FOR SELECT USING (
        requester_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
        OR addressee_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
    );

CREATE POLICY "Users can create friend requests" ON friendships
    FOR INSERT WITH CHECK (
        requester_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
    );

CREATE POLICY "Users can update friendship status" ON friendships
    FOR UPDATE USING (
        addressee_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
        OR requester_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
    );

-- RLS policies for activities
CREATE POLICY "Users can view activities from friends and public" ON activities
    FOR SELECT USING (
        user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
        OR user_id IN (
            SELECT CASE 
                WHEN requester_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)) THEN addressee_id
                ELSE requester_id
            END
            FROM friendships
            WHERE status = 'accepted'
            AND (
                requester_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
                OR addressee_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true))
            )
        )
    );

CREATE POLICY "Users can create their own activities" ON activities
    FOR INSERT WITH CHECK (user_id = (SELECT id FROM users WHERE firebase_uid = current_setting('app.current_user_uid', true)));
