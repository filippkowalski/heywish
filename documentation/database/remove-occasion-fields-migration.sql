-- Migration: Remove occasion_type and event_date from wishlists table
-- Description: Clean up wishlist schema by removing unused occasion and event date fields
-- Date: 2025-08-14

-- Remove occasion_type and event_date columns from wishlists table
ALTER TABLE wishlists 
DROP COLUMN IF EXISTS occasion_type,
DROP COLUMN IF EXISTS event_date;

-- Note: This migration should be run on the backend database
-- The mobile app has been updated to remove all UI and model references to these fields