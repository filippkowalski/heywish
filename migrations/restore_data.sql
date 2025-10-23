-- Restore backed up data
-- Run this after applying the new baseline schema

-- Temporarily disable triggers to avoid conflicts during restore
SET session_replication_role = replica;

-- Restore users (only columns that exist in both old and new schema)
\copy users (id, firebase_uid, email, email_verified, username, full_name, avatar_url, bio, location, birthdate, interests, gender, phone_number, notification_preferences, privacy_settings, sign_up_method, created_at, updated_at, last_seen) FROM '/tmp/jinnie_users_backup.csv' WITH CSV HEADER;

-- Restore wishlists (map old columns to new schema)
\copy wishlists (id, user_id, name, description, visibility, wishlist_type, cover_image_url, share_token, share_password, share_expires_at, item_count, reserved_count, created_at, updated_at) FROM '/tmp/jinnie_wishlists_backup.csv' WITH CSV HEADER;

-- Restore wishes (only columns that exist in both schemas)
\copy wishes (id, wishlist_id, title, description, url, price, currency, images, status, priority, quantity, notes, reserved_by, reserved_at, reserved_message, position, source, metadata, created_at, updated_at) FROM '/tmp/jinnie_wishes_backup.csv' WITH CSV HEADER;

-- Restore friendships
\copy friendships (id, requester_id, addressee_id, status, created_at, updated_at) FROM '/tmp/jinnie_friendships_backup.csv' WITH CSV HEADER;

-- Restore activities
\copy activities (id, user_id, activity_type, data, created_at) FROM '/tmp/jinnie_activities_backup.csv' WITH CSV HEADER;

-- Re-enable triggers
SET session_replication_role = DEFAULT;

\echo 'Data restore completed!'
