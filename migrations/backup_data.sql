-- Backup current database data
-- Run this before applying the new baseline schema

\copy (SELECT * FROM users) TO '/tmp/jinnie_users_backup.csv' WITH CSV HEADER;
\copy (SELECT * FROM wishlists) TO '/tmp/jinnie_wishlists_backup.csv' WITH CSV HEADER;
\copy (SELECT * FROM wishes) TO '/tmp/jinnie_wishes_backup.csv' WITH CSV HEADER;
\copy (SELECT * FROM friendships) TO '/tmp/jinnie_friendships_backup.csv' WITH CSV HEADER;
\copy (SELECT * FROM activities) TO '/tmp/jinnie_activities_backup.csv' WITH CSV HEADER;

-- Optional: backup other tables if they have data
-- \copy (SELECT * FROM wishlist_tags) TO '/tmp/jinnie_wishlist_tags_backup.csv' WITH CSV HEADER;
-- \copy (SELECT * FROM wish_variants) TO '/tmp/jinnie_wish_variants_backup.csv' WITH CSV HEADER;
-- \copy (SELECT * FROM wish_price_history) TO '/tmp/jinnie_wish_price_history_backup.csv' WITH CSV HEADER;

\echo 'Backup completed! Files saved to /tmp/'
