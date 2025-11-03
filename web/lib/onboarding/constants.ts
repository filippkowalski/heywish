/**
 * Onboarding constants and data structures
 * Based on mobile app implementation
 */

export const SHOPPING_CATEGORIES = [
  { id: 'fashion', emoji: '👕', label: 'Fashion', color: '#EC4899' },
  { id: 'beauty', emoji: '💄', label: 'Beauty & Style', color: '#F97316' },
  { id: 'electronics', emoji: '📱', label: 'Electronics', color: '#3B82F6' },
  { id: 'home', emoji: '🏠', label: 'Home & Decor', color: '#10B981' },
  { id: 'books', emoji: '📚', label: 'Books', color: '#8B5CF6' },
  { id: 'sports', emoji: '⚽', label: 'Sports', color: '#F59E0B' },
  { id: 'toys', emoji: '🧸', label: 'Toys & Games', color: '#EF4444' },
  { id: 'jewelry', emoji: '💎', label: 'Jewelry', color: '#06B6D4' },
  { id: 'food', emoji: '🍔', label: 'Food', color: '#FBBF24' },
  { id: 'art', emoji: '🎨', label: 'Art', color: '#A855F7' },
  { id: 'music', emoji: '🎵', label: 'Music', color: '#14B8A6' },
  { id: 'outdoor', emoji: '⛺', label: 'Outdoors', color: '#22C55E' },
] as const;

export const GENDER_OPTIONS = [
  { value: 'male', label: 'Male' },
  { value: 'female', label: 'Female' },
  { value: 'other', label: 'Other' },
  { value: 'prefer_not_to_say', label: 'Prefer not to say' },
] as const;

export type Gender = typeof GENDER_OPTIONS[number]['value'];
export type ShoppingCategory = typeof SHOPPING_CATEGORIES[number]['id'];

// Username validation regex (lowercase, numbers, periods, underscores)
export const USERNAME_PATTERN = /^[a-z0-9._]+$/;

export function validateUsername(username: string): string | null {
  if (!username) return 'Username is required';
  if (username.length < 3) return 'Username must be at least 3 characters';
  if (username.length > 30) return 'Username must be 30 characters or less';
  if (username.includes(' ')) return 'Username cannot contain spaces';
  if (!USERNAME_PATTERN.test(username)) {
    return 'Username can only contain lowercase letters, numbers, periods, and underscores';
  }
  if (username.startsWith('.') || username.endsWith('.')) {
    return 'Username cannot start or end with a period';
  }
  if (username.includes('..')) return 'Username cannot have consecutive periods';
  return null;
}

export interface OnboardingData {
  username?: string;
  birthdate?: string; // YYYY-MM-DD format
  gender?: Gender;
  shopping_interests?: string[];
}

export type OnboardingStep = 'interests' | 'profile' | 'username' | 'complete';
