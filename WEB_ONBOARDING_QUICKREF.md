# Web Onboarding Implementation - Quick Reference

## Shopping Categories (Copy-Paste Ready)

```typescript
const SHOPPING_CATEGORIES = [
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
];
```

## Gender Options

```typescript
const GENDER_OPTIONS = [
  { value: 'male', label: 'Male', icon: '♂️' },
  { value: 'female', label: 'Female', icon: '♀️' },
  { value: 'other', label: 'Other', icon: '✦' },
  { value: 'prefer_not_to_say', label: 'Prefer not to say', icon: '🔒' },
];
```

## Notification Preferences (Default All True)

```typescript
const NOTIFICATION_PREFERENCES = {
  birthday_notifications: true,
  coupon_notifications: true,
  discount_notifications: true,
  friend_activity: true,
  wishlist_updates: true,
};
```

## Username Validation Regex

```typescript
const USERNAME_PATTERN = /^[a-z0-9._]+$/;

function validateUsername(username: string): string | null {
  if (!username) return null; // Empty is OK (for optional display)
  if (username.length < 3) return 'Username must be at least 3 characters';
  if (username.length > 30) return 'Username must be 30 characters or less';
  if (username.includes(' ')) return 'Username cannot contain spaces';
  if (!USERNAME_PATTERN.test(username)) {
    return 'Username can only contain letters, numbers, periods, and underscores';
  }
  if (username.startsWith('.') || username.endsWith('.')) {
    return 'Username cannot start or end with a period';
  }
  if (username.includes('..')) return 'Username cannot have consecutive periods';
  return null; // Valid
}
```

## API Request Format

```typescript
interface OnboardingData {
  username: string; // REQUIRED
  full_name?: string;
  birthdate?: string; // YYYY-MM-DD format
  gender?: 'male' | 'female' | 'other' | 'prefer_not_to_say';
  shopping_interests?: string[];
  notification_preferences?: {
    birthday_notifications: boolean;
    coupon_notifications: boolean;
    discount_notifications: boolean;
    friend_activity: boolean;
    wishlist_updates: boolean;
  };
  privacy_settings?: {
    phone_discoverable: boolean;
    show_birthday: boolean;
    show_gender: boolean;
  };
}

// POST to /api/v1/users/profile (or similar)
const response = await fetch('/api/v1/users/profile', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${idToken}`,
  },
  body: JSON.stringify(onboardingData),
});
```

## Onboarding Step Order

1. Welcome (no skip)
2. Shopping Interests (optional)
3. Profile Details: Birthday + Gender (required to continue)
4. Notifications (optional)
5. Account Creation: Google/Apple Sign In (skip allows anonymous)
6. Username (CRITICAL - cannot skip, must be available)
7. Complete (success screen)

## Critical Implementation Points

### Username Step
- MUST have real-time availability checking
- MUST validate against regex locally first
- MUST show debounced API call status
- MUST prevent proceeding without "Available" status
- MUST auto-lowercase input
- SHOULD pre-fill from email if available

### Profile Details
- Birthday is shown as required in UI
- Gender is shown as required in UI
- But data model allows null (optional when saving)
- Both fields must have selection before continuing

### Shopping Interests
- At least 1 category should be selected to show "Continue"
- But skipping is allowed
- Selected count shown at bottom

### Authentication
- Username comes AFTER sign-up/sign-in
- Can skip account creation (anonymous flow)
- But still need username for completion

## State Management Pattern

Mobile uses Provider for state, web should use similar pattern:

```typescript
class OnboardingState {
  step: OnboardingStep;
  data: OnboardingData;
  isLoading: boolean;
  error?: string;
  usernameCheckResult?: 'Available' | 'Checking...' | 'Taken' | ValidationError;
  usernameSuggestions?: string[];
  
  nextStep(): void;
  previousStep(): void;
  goToStep(step: OnboardingStep): void;
  updateData(key: keyof OnboardingData, value: any): void;
  checkUsernameAvailability(username: string): Promise<void>;
  completeOnboarding(): Promise<boolean>;
}
```

## Responsive Design Notes

Mobile uses:
- Full-width single column
- Large typography (32-34px titles)
- Bottom sheets for modals
- Safe area padding awareness

Web should:
- Consider max-width constraint (desktop)
- Adapt to mobile browsers
- Use modals/drawers instead of bottom sheets
- Standard web breakpoints

## Color Scheme

Primary accent: Use from app theme (appears to be a blue/purple)
Text primary: #000000 (black)
Text secondary: A darker shade (appears to be gray-700ish)
Outline: Subtle borders
Background: #F5F5F5 or white

## Key Takeaways for Web Implementation

1. **Username cannot be optional** - It's the gate to completion
2. **Shopping categories are predefined** - Don't allow custom entries
3. **Birthday and Gender UI shows them required** - Even if optional in backend
4. **Notification preferences have defaults** - All start as true
5. **Social auth must come before username** - Can't claim username without auth
6. **Progressive disclosure** - Each step reveals next step type
7. **Debounced validation** - Username check should wait 500ms after user stops typing
8. **Retry logic needed** - Network calls can fail, implement backoff
9. **Localization ready** - Use i18n/translation keys, not hardcoded strings
10. **Mobile-first was designed** - Web is secondary, adapt but don't diverge too much

