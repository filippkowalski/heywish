# Jinnie Mobile App Onboarding Flow - Complete Analysis

## Overview
The mobile app uses a **7-step onboarding flow** managed by `OnboardingService` with state tracking in Flutter's Provider pattern. The onboarding is required for authenticated users and optional for anonymous users.

---

## Onboarding Steps (In Order)

### 1. **Welcome Step** (`WelcomeStep`)
**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/screens/onboarding/widgets/welcome_step.dart`

**Purpose:** First impression and orientation
- Shows welcome background image with gradient overlay
- Animated staggered entrance of title, description, and buttons
- **Two paths from here:**
  - "Get Started" button → Shopping Interests (new user flow)
  - "Already have an account?" → Sign In Bottom Sheet (existing user flow)

**Key Features:**
- Beautiful background image with text overlay
- Staggered fade + slide animations
- No back button available

---

### 2. **Shopping Interests Step** (`ShoppingInterestsStep`)
**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/screens/onboarding/widgets/shopping_interests_step.dart`

**Purpose:** Engage users early with visual category selection
- Multi-select chips for shopping interests
- Optional step (can skip)
- Updates `onboardingService.updateShoppingInterests()`

**Shopping Categories (12 total):**
```
ID              | Emoji | Label          | Color
─────────────────────────────────────────────────
fashion         | 👕   | Fashion        | Pink (#EC4899)
beauty          | 💄   | Beauty & Style | Orange (#F97316)
electronics     | 📱   | Electronics    | Blue (#3B82F6)
home            | 🏠   | Home & Decor   | Green (#10B981)
books           | 📚   | Books          | Purple (#8B5CF6)
sports          | ⚽   | Sports         | Amber (#F59E0B)
toys            | 🧸   | Toys & Games   | Red (#EF4444)
jewelry         | 💎   | Jewelry        | Cyan (#06B6D4)
food            | 🍔   | Food           | Yellow (#FBBF24)
art             | 🎨   | Art            | Purple (#A855F7)
music           | 🎵   | Music          | Teal (#14B8A6)
outdoor         | ⛺   | Outdoors       | Green (#22C55E)
```

**Key Features:**
- Skip button available
- Selection counter at bottom
- Continue button only enabled when at least 1 category selected

---

### 3. **Profile Details Step** (`ProfileDetailsStep`)
**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/screens/onboarding/widgets/profile_details_step.dart`

**Purpose:** Collect demographic information (optional but required to continue)
- **Two required fields:**
  1. **Birthday:** CupertinoPicker with Month/Day/Year spinners
  2. **Gender:** 4-option selector (Male, Female, Other, Prefer not to say)

**Gender Options:**
```
Value                 | Label                    | Icon                | Color
──────────────────────────────────────────────────────────────────────────
male                  | Male                     | Icons.male          | Blue (#3B82F6)
female                | Female                   | Icons.female        | Pink (#EC4899)
other                 | Other                    | Icons.transgender   | Purple (#8B5CF6)
prefer_not_to_say     | Prefer not to say        | Icons.lock_outline  | Gray (#6B7280)
```

**Key Features:**
- Both fields are REQUIRED to continue
- Beautiful modal bottom sheet for date picker
- CupertinoPicker (native iOS/Android spinner)
- Animated colored buttons for gender selection
- Skip button available

---

### 4. **Notifications Step** (`NotificationsStep`)
**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/screens/onboarding/widgets/notifications_step.dart`

**Purpose:** Request notification permissions and set preferences
- Requests push notification permission
- Sets 5 notification preference toggles
- Optional step (continue even if permission denied)

**Notification Preferences:**
- `birthday_notifications` (default: true)
- `coupon_notifications` (default: true)
- `discount_notifications` (default: true)
- `friend_activity` (default: true)
- `wishlist_updates` (default: true)

**Key Features:**
- Uses FCM service for permission request
- Handles iOS permanent denial gracefully
- Shows dialog if permissions permanently denied
- Updates: `onboardingService.updateNotificationPreference(key, value)`

---

### 5. **Account Creation Step** (`AccountCreationStep`)
**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/screens/onboarding/widgets/account_creation_step.dart`

**Purpose:** Offer account creation with social auth
- Shows benefits of creating account (3 benefit cards)
- Sign up options: Apple (iOS only) + Google
- Skip button to continue anonymously

**Benefits Highlighted:**
1. "Sync Across Devices" - Sync data across devices
2. "Never Lose Your Wishlists" - Secure backup
3. "Claim Your Unique Username" - Get a username

**Key Features:**
- Beautiful animated mesh gradient background (3 blob animations)
- Platform-specific: Apple button only on iOS
- Google button on both platforms
- Skip button allows anonymous continuation

---

### 6. **Username Step** (`UsernameStep`)
**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/screens/onboarding/widgets/username_step.dart`

**Purpose:** Claim username and complete profile setup
- **CRITICAL:** This is the ONLY step that cannot be skipped
- Real-time username availability checking with debounce
- Instagram-style validation rules

**Username Validation Rules:**
- Minimum length: 3 characters
- Maximum length: 30 characters
- Allowed characters: a-z, 0-9, periods (.), underscores (_)
- No spaces allowed
- Cannot start/end with period
- No consecutive periods
- Auto-converted to lowercase

**Key Features:**
- Pre-fills from email if available (excludes Apple anonymous emails)
- Live availability checking (500ms debounce)
- Shows "@" prefix icon
- Shows "jinnie.co/username" URL preview
- 3 status states:
  - Red: Validation error
  - Yellow: Checking availability
  - Green: Available
- Suggestions provided if username taken

**Critical Logic:**
```
✓ Can proceed ONLY if:
  - Username passes all validation rules
  - Username availability check returns "Available"
  - Cannot proceed to complete step without valid username
```

---

### 7. **Onboarding Complete Step** (`OnboardingCompleteStep`)
**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/screens/onboarding/widgets/onboarding_complete_step.dart`

**Purpose:** Celebrate account creation and show next steps
- Shows username with profile card
- Copy profile link button
- Lists 3 key features
- Navigation to home screen

**Features Highlighted:**
1. "Create wishlists" - Organize wishes beautifully
2. "Share with friends" - Let others know what you want
3. "Get the perfect gift" - Never miss what matters

**Key Actions:**
- Copy profile link to clipboard (shows checkmark)
- "Start Adding Wishes" button navigates to home
- Calls `authService.markOnboardingCompleted()`
- Handles anonymous user profile saving

---

## OnboardingService Architecture

**File:** `/Users/filip.zapper/Workspace/jinnie/mobile/lib/services/onboarding_service.dart`

### OnboardingStep Enum
```dart
enum OnboardingStep {
  welcome,
  shoppingInterests,
  profileDetails,
  notifications,
  accountCreation,
  checkUserStatus,
  username,
  complete,
}
```

### OnboardingData Model
Stores all onboarding information:
```dart
class OnboardingData {
  String? username;              // Required for completion
  String? fullName;              // Optional
  String? email;                 // From auth
  DateTime? birthday;            // Optional in data
  String? gender;                // Optional in data
  List<String> shoppingInterests; // Categories selected
  Map<String, bool> notificationPreferences;
}
```

### Key Service Methods

| Method | Purpose |
|--------|---------|
| `nextStep()` | Move to next step with conditional logic |
| `previousStep()` | Move to previous step (limited) |
| `goToStep(step)` | Jump to specific step (validates username) |
| `checkUserProfileStatus()` | Auto-determine next step after auth |
| `checkUsernameAvailability()` | API call with retry & backoff |
| `completeOnboarding()` | Save all data to backend |
| `markOnboardingCompleted()` | Flag in AuthService |
| `updateUsername()` | Set username with debounced check |
| `updateBirthday()` | Set birthday |
| `updateGender()` | Set gender |
| `updateShoppingInterests()` | Set categories |
| `updateNotificationPreference()` | Toggle notification setting |

### Error Handling & Retry Logic

**Username Availability Check:**
- Max 3 retries with exponential backoff (1s, 2s, 4s)
- Retries on: socket, timeout, connection, server errors
- No retry on: 400, 401, 403, 404

**Profile Completion:**
- Max 2 retries with exponential backoff (1.5s, 3s)
- Retries on: socket, timeout, connection, network, server errors
- No retry on: 409 (conflict), 422 (validation), 400 (bad request)

---

## Flow Logic

### New User Sign Up Path
```
Welcome
  ↓
Shopping Interests (Optional, skip available)
  ↓
Profile Details (Birthday + Gender required)
  ↓
Notifications (Optional, skip available)
  ↓
Account Creation (Choose: Sign up or Skip)
  ├─ If Skip → Skip Username → Anonymous user
  ├─ If Google/Apple → Check User Status
  │    ├─ If existing user → Username
  │    └─ If new user → Username
  ↓
Username (REQUIRED, cannot skip)
  ↓
Complete ✓
```

### Existing User Sign In Path (from Welcome)
```
Welcome → "Already have an account?" (bottom sheet)
  ↓
Sign In → Auth → Check User Status
  ├─ If username exists → Skip to Complete
  └─ If no username → Username step → Complete
```

### Key Conditional Logic

**In `nextStep()` method:**
- If `_hasAlreadySignedIn` is true, skip account creation
- If `_skipUsernameStep` is true (anonymous), skip to complete
- If username step reached, cannot proceed without valid username

---

## Onboarding Completion Tracking

**AuthService Storage:**
```dart
// In SharedPreferences
'onboarding_completed' → Boolean flag

// In AuthService class
bool get isOnboardingCompleted
bool get needsOnboarding  // isAuthenticated && !isOnboardingCompleted
void markOnboardingCompleted() // Sets flag to true
```

**Completion Conditions:**
1. User must be authenticated (Firebase user)
2. User must have valid username (3-30 chars)
3. User must call `authService.markOnboardingCompleted()`
4. Flag is persisted in SharedPreferences

**Auto-completion Check:**
When user signs in later, if username exists, onboarding is auto-marked complete.

---

## Data Sent to Backend

When `completeOnboarding()` is called, this data structure is sent:

```json
{
  "username": "string (required)",
  "full_name": "string or null",
  "birthdate": "YYYY-MM-DD format or null",
  "gender": "male|female|other|prefer_not_to_say or null",
  "shopping_interests": ["fashion", "beauty", ...],
  "notification_preferences": {
    "birthday_notifications": true,
    "coupon_notifications": true,
    "discount_notifications": true,
    "friend_activity": true,
    "wishlist_updates": true
  },
  "privacy_settings": {
    "phone_discoverable": false,
    "show_birthday": true,
    "show_gender": false
  }
}
```

---

## UI/UX Patterns Used

1. **Native Page Transitions** - Platform-specific animations (iOS 350ms, Android 300ms)
2. **Bottom Sheets** - For modals like date picker
3. **Animated Chips** - For category selection
4. **Staggered Animations** - For entrance effects
5. **Debounced API Calls** - For username availability
6. **Optimistic UI** - Shows "Checking..." immediately
7. **Loading States** - Buttons disabled, spinners shown
8. **Color-coded Status** - Red (error), Yellow (loading), Green (success)

---

## Key Files Summary

| File | Purpose |
|------|---------|
| `onboarding_flow_screen.dart` | Main orchestrator with AnimatedSwitcher |
| `onboarding_service.dart` | State management & API calls |
| `welcome_step.dart` | Beautiful intro screen |
| `shopping_interests_step.dart` | Category multi-select |
| `profile_details_step.dart` | Birthday + Gender collection |
| `notifications_step.dart` | Permission + preferences |
| `account_creation_step.dart` | Social auth options |
| `username_step.dart` | Username with real-time validation |
| `onboarding_complete_step.dart` | Success celebration |

---

## Important Notes for Web Implementation

1. **Username is CRITICAL** - Cannot skip or bypass this step
2. **Profile Details Validation** - Birthday and Gender are marked required in UI (both fields needed to proceed)
3. **Shopping Interests** - 12 predefined categories with IDs and colors
4. **Notification Preferences** - 5 toggle settings with default true
5. **Social Auth First** - Users must sign in/up before username
6. **Error Handling** - Retry logic with exponential backoff for network resilience
7. **Data Structure** - `OnboardingData` class with optional fields (only username is required)
8. **Localization** - All strings use easy_localization with `.tr()` extension
9. **Platform Differences** - iOS shows Apple + Google, Android shows Google only
10. **Anonymous Users** - Can skip account creation, but still need username for complete onboarding

