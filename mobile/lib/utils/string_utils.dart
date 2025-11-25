// String utility functions for the Jinnie app
//
// Provides common string manipulation functions used across the app,
// including URL-safe slug generation for wishlist names and usernames.

/// Converts a string into a URL-safe slug
///
/// This function:
/// - Converts to lowercase
/// - Replaces all non-alphanumeric characters with hyphens
/// - Collapses multiple consecutive hyphens into one
/// - Removes leading and trailing hyphens
///
/// Examples:
/// - "Christmas/Hanukkah" → "christmas-hanukkah"
/// - "My Wishlist!" → "my-wishlist"
/// - "Hello   World" → "hello-world"
///
/// This matches the web version's slugify logic for consistency across platforms.
String slugify(String value) {
  if (value.isEmpty) return '';

  final lower = value.toLowerCase();
  // Replace all non-alphanumeric characters (including spaces, slashes, etc.) with hyphens
  final sanitized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  // Collapse multiple consecutive hyphens into one
  final collapsed = sanitized.replaceAll(RegExp(r'-{2,}'), '-');
  // Remove leading and trailing hyphens
  return collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Gets a URL-safe wishlist slug from wishlist data
///
/// Priority order:
/// 1. Use explicit slug field if provided
/// 2. Slugify the wishlist name
/// 3. Fall back to share token if name is empty
/// 4. Fall back to ID if both name and share token are empty
/// 5. Return "wishlist" as last resort
///
/// This ensures we always have a valid, user-friendly URL for wishlists.
String getWishlistSlug({
  String? slug,
  String? name,
  String? shareToken,
  String? id,
}) {
  // Use explicit slug if available
  if (slug != null && slug.trim().isNotEmpty) {
    return slug.trim().toLowerCase();
  }

  // Slugify the name if available
  if (name != null && name.trim().isNotEmpty) {
    final slugified = slugify(name.trim());
    if (slugified.isNotEmpty) {
      return slugified;
    }
  }

  // Fall back to share token
  if (shareToken != null && shareToken.isNotEmpty) {
    return 'wishlist-${shareToken.substring(0, shareToken.length > 8 ? 8 : shareToken.length).toLowerCase()}';
  }

  // Fall back to ID
  if (id != null && id.isNotEmpty) {
    return 'wishlist-${id.toLowerCase()}';
  }

  // Last resort
  return 'wishlist';
}
