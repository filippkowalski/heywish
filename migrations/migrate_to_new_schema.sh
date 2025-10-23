#!/bin/bash

# Migration script to upgrade Jinnie database to new schema
# This script:
# 1. Backs up current data
# 2. Drops and recreates the database with new schema
# 3. Restores the backed up data

set -e  # Exit on error

DB_URL="postgresql://neondb_owner@ep-cold-credit-adxn1idu-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require"
PGPASSWORD="npg_5YXen0aqSRiy"

echo "🚀 Starting database migration to new schema..."
echo ""

# Step 1: Backup current data
echo "📦 Step 1: Backing up current data..."
PGPASSWORD=$PGPASSWORD psql "$DB_URL" -f backup_data.sql
echo "✅ Backup completed!"
echo ""

# Step 2: Drop all tables (in correct order due to foreign keys)
echo "🗑️  Step 2: Dropping old tables..."
PGPASSWORD=$PGPASSWORD psql "$DB_URL" <<EOF
DROP TABLE IF EXISTS activities CASCADE;
DROP TABLE IF EXISTS wish_price_history CASCADE;
DROP TABLE IF EXISTS wish_variants CASCADE;
DROP TABLE IF EXISTS wishlist_tags CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS wishes CASCADE;
DROP TABLE IF EXISTS wishlists CASCADE;
DROP TABLE IF EXISTS users CASCADE;
EOF
echo "✅ Old tables dropped!"
echo ""

# Step 3: Create new schema
echo "🏗️  Step 3: Creating new schema..."
PGPASSWORD=$PGPASSWORD psql "$DB_URL" -f 20250309_baseline.sql
echo "✅ New schema created!"
echo ""

# Step 4: Restore data
echo "📥 Step 4: Restoring backed up data..."
PGPASSWORD=$PGPASSWORD psql "$DB_URL" -f restore_data.sql
echo "✅ Data restored!"
echo ""

# Step 5: Cleanup backup files
echo "🧹 Step 5: Cleaning up backup files..."
rm -f /tmp/jinnie_*_backup.csv
echo "✅ Cleanup completed!"
echo ""

echo "🎉 Migration completed successfully!"
echo "📊 Database is now running on the new schema with all data preserved."
