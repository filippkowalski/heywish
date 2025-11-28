# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## App Name: Jinnie

**Jinnie** is our brand name, inspired by genies and djinn from mythology. The name was chosen for several strategic reasons:

## Git Workflow & Commit Policy

**IMPORTANT - REQUIRES APPROVAL BEFORE COMMITS:**
- **NEVER commit or push changes automatically**
- **ALWAYS ask for user approval before creating commits**
- Present a summary of changes and wait for explicit confirmation
- This app has active users - all commits must be reviewed before deployment
- **Major changes MUST be submitted as Pull Requests** using `gh pr create` for code review
- Minor fixes can be committed directly after approval

Instructions:
- Run 'flutter analyze' everytime you do some bigger change to verify that the build will build, same applies for web with npm build, especially before we push changes to the repository (auto-build)
- After completing work, present changes to user and await approval before committing
- When user approves, create descriptive commit messages following conventional commits format

### Why "Jinnie"?

1. **Sound and Feel**:
   - Short, warm, and phonetic - rolls off the tongue easily
   - Sounds friendly and approachable (like "Jenny") but with a magical twist
   - Natural to say: "I'll add it to Jinnie"

2. **Meaning and Association**:
   - Instantly recalls genie/djinn without being heavy or exoticized
   - Represents the approachable, modern descendant of mythic wish-granters
   - Perfect for a wishlist app - the helper who quietly makes wishes happen

3. **Brandability**:
   - Easy to spell and pronounce globally
   - Works across multiple markets (English, Spanish, Portuguese speakers)
   - Can be personified as a digital genie mascot
   - Better domain availability than "genie.app"

4. **Emotional Tone**:
   - Approachable yet enchanting
   - Think "Duolingo meets Aladdin"
   - Whisper of magic without being overpowering

### Future Brand Direction
The "Jinnie" character can be developed as a mascot - a modern genie who manages your wishes and makes gift-giving magical. Brand around "your modern genie" concept.

## App Features Overview

Jinnie combines wishlist management, social features, and gift coordination across mobile (Flutter) and web (Next.js) platforms.

### Mobile App Pages/Screens (Flutter)
- **Authentication & Onboarding**: Splash screen, login/signup, 7-step guided onboarding (username, profile, notifications, friend discovery, account creation)
- **Main Navigation**: Home/Wishlists tab (view/create wishlists), Discover tab (categories/people search), Profile tab
- **Wishlist & Item Management**: Wishlist detail/edit/create screens, add/edit wish screens
- **Social Features**: Friends screen (friends/requests tabs), Activity feed with filters

### Web App Surface (Next.js)
- **Landing**: Minimal lookup form for usernames or share tokens (`/`).
- **Profile View**: Read-only public profile page showing published wishlists (`/[username]`).
- **Wishlist View**: Public wishlist detail with reservation dialog (`/[username]/[wishlist]`, legacy share links: `/w/[token]`).
- **Email Verify**: Magic-link completion page for reservations (`/verify-reservation`).
- **Dynamic OG Images**: Personalized social sharing previews generated at `/api/og/profile/[username]`. Shows user avatar, wish images as floating bubbles, and custom messaging. See `web/docs/OG_IMAGE_IMPLEMENTATION.md` for details.
- **Scope**: Web is presently read-only—creation and editing remain mobile-only.

### General Features (Cross-Platform)
- **Authentication**: Firebase integration (anonymous, Google, Apple, email/password), account linking
- **Core Services**: API integration, wishlist management, social/friends, contact integration
- **Offline & Sync**: Local SQLite database, offline-first architecture, background sync
- **Media & Content**: Cloudflare R2 image management, URL scraping, cached images
- **UI/UX**: Skeleton loading, Material Design 3, multi-language support, optimistic UI
- **Backend**: Global search, reservation system, activity feeds, file uploads, sharing system

## Project Overview

Jinnie is a next-generation wishlist platform that aims to compete with GoWish by offering a modern, fast, and social-first experience targeting younger demographics.

## Technology Stack

- **Backend/Web**: Next.js 14 with App Router (modular monolith approach)
- **Authentication**: Firebase Auth (free tier, no Identity Platform)
- **Database**: PostgreSQL hosted on Render.com
- **Mobile**: Flutter
- **Styling**: Tailwind CSS (for web)
- **Infrastructure**: Cloudflare Pages for deployment
- **CDN/Storage**: Cloudflare R2 (images storage)

## Architecture Principles

- **Modular Monolith**: The backend is implemented as a modular monolith within the Next.js application, using API routes organized by domain (auth, wishlists, wishes, users, social).
- **Authentication Flow**: Firebase handles auth, and user data is synced to the PostgreSQL database on first login.
- **Database**: A single PostgreSQL instance is used, hosted on Render.com.

## Key Documentation Files

Review these files for context:
- `docs/DESIGN_SYSTEM.md` - UI components and styling guidelines
- `docs/API_SPECIFICATION.md` - Detailed description of the REST API.
- `docs/TECHNICAL_SPEC.md` - Database schema and technical details.
- `mobile/AUTHENTICATION.md` - **Comprehensive authentication system documentation** including authentication flows, account merging, data refresh after merge, troubleshooting, and testing guidelines.
- `web/docs/OG_IMAGE_IMPLEMENTATION.md` - **Dynamic OG image generation** for social sharing. Covers API route architecture, design specs, caching strategy, and troubleshooting.

## Database Schema

The PostgreSQL schema is defined in `docs/TECHNICAL_SPEC.md`. Key tables include:
- `users` - User accounts synced from Firebase (includes firebase_uid)
- `wishlists` - User wishlists with visibility settings
- `wishes` - Individual wish items with reservation status
- Social features tables (friends, activity feed)

## Authentication Integration

1. Mobile requires Firebase-authenticated users; the current web preview allows anonymous browsing/reservations.
2. When auth is enabled, Firebase handles email/password, Google, and Apple flows.
3. On any Firebase authentication event, the `/api/auth/sync` endpoint creates or updates the user in PostgreSQL.
4. Authenticated API calls include a Firebase ID token in the `Authorization` header and are verified server-side.

**IMPORTANT**: For detailed information about authentication flows, account merging, data refresh patterns, and troubleshooting, see `mobile/AUTHENTICATION.md`. This document covers:
- All authentication providers (Anonymous, Google, Apple, Email/Password)
- Account merging flow with hybrid detection (server + local SQLite)
- Automatic data refresh after merge using reactive timestamps
- Error handling and recovery patterns
- Testing procedures and troubleshooting guides

## API Structure

The REST API is implemented using Next.js API routes. Key characteristics include:
- Base path: `/api/v1`
- Authentication: Firebase ID tokens are verified on the backend.
- Standard HTTP methods and status codes are used.
- The request and response format is JSON.
- Key authentication endpoints include `/api/auth/sync` and `/api/auth/verify`.

## WEB Guidelines
- Shadcn design, black and white, elegant, sleek
- Tailwind.css, React

### Cloudflare Pages Deployment

**`web/` (public app)** - Uses **OpenNext** (`@opennextjs/cloudflare`)
- **NO `export const runtime = 'edge'` needed** - OpenNext handles runtime automatically
- Build command: `npm run cf:build` (uses `opennextjs-cloudflare build`)
- Preview locally: `npm run preview` (builds and runs preview server)
- Deploy: `npm run deploy` (builds and deploys to Cloudflare)
- Configuration files: `wrangler.jsonc`, `open-next.config.ts`
- Build output: `.open-next/` directory (gitignored)

**`web-internal-dashboard/` (admin)** - Uses legacy **@cloudflare/next-on-pages**
- **⚠️ STILL requires `export const runtime = 'edge';` on ALL dynamic routes**
- Build command: `npm run pages:build`
- Any new page with dynamic segments MUST have edge runtime export

**Key differences:**
| Feature | web/ (OpenNext) | web-internal-dashboard/ (next-on-pages) |
|---------|-----------------|----------------------------------------|
| Runtime export | Not needed | Required on dynamic routes |
| Build command | `npm run cf:build` | `npm run pages:build` |
| `next/og` ImageResponse | ✅ Works | ❌ Returns 0 bytes |
| Node.js APIs | Limited support | Not available |

**Required pattern for web-internal-dashboard dynamic routes:**
```typescript
'use client';

export const runtime = 'edge';

// ... rest of imports and component code
```

- Please use the playwright MCP server when making visual changes to the front-end website to check your work

## Mobile Guidelines
Design
- Use light mode, white and grey colors, neutral
- Make sure not to hardcode colors, we want to use system/Flutter available options such as theme colorScheme etc.this will make it easier for us to add different theme modes in the future
- Use Shadcn design principles, make it beautiful and minimalistic, beautiful typography, main text is black and subtitles are usually a shade darker
- Remember about proper padding, spacing between elements and styling (again get inspiration from Shadcn design principles)
- Only use colors for accent and whenever absolutely necessary
- Less is better, we want the UI and UX to be minimalistic but also user friendly, we want user to create invoices effortlessly and quickly, if you have any idea on how we can improve something and make it easier to use, feel free to discuss it with me, we focus on core feature
- Never use gray borders with shadows. Instead, use a semi-transparent outline so the bottom edge blends with the shadow and gets darker, avoiding a 'muddy' appearance. This makes the design look 'crisp'.

- Use easy_localization for all user-facing strings
- **IMPORTANT**: Never hardcode user-facing strings. Always use localization keys from `assets/translations/en.json`
- Follow the localization key structure: `category.specific_string` (e.g., `auth.sign_in`, `wishlist.create_new`, `errors.network_error`)
- When adding new features, always add corresponding strings to the translation file first
- Use `.tr()` extension on all localization keys

### Image Loading & Caching
- **ALWAYS use cached image widgets for all network images**
- **Available widgets**:
  - `CachedImageWidget` - For general images (wish images, wishlist covers, etc.)
  - `CachedAvatarImage` - For profile pictures and user avatars
  - `MasonryWishCard` - Already uses cached images internally
- **NEVER use `Image.network` or `NetworkImage` directly** - always use `CachedNetworkImage` or the wrapper widgets above
- **Benefits**: Automatic disk caching, faster loading, reduced network usage, better offline experience
- **Default cache settings**: 7 days stale period, 30 days max age, 200 files max (automatic cleanup)
- Located in: `lib/widgets/cached_image.dart`, `lib/common/widgets/masonry_wish_card.dart`

### Page Transitions & Native Navigation (CRITICAL)
- **ALWAYS use native transitions for all navigation**
- **Implementation**: Use the `NativePageRoute` and `NativeTransitions` utilities from `lib/common/navigation/native_page_route.dart`
- **GoRouter Integration**: All routes MUST use `NativeTransitions.page()` for native transitions
- **Modal Presentations**: Use `NativeTransitions.showNativeModalBottomSheet()` and `NativeTransitions.showNativeDialog()`
- **In-Flow Transitions**: For AnimatedSwitcher (e.g., onboarding steps), use `NativeTransitions.buildPageTransition()`
- **Platform-Specific Behavior**:
  - **iOS**: Uses `CupertinoPageTransition` with parallax effect, `showCupertinoModalPopup`, `showCupertinoDialog`
  - **Android**: Uses Material Design transitions with fade+slide, proper curves (fastOutSlowIn), and timing
- **Platform-Specific Timing**:
  - **iOS**: 350ms transition duration for authentic feel
  - **Android**: 300ms with Material curves for snappy performance
- **Fallback Strategy**: When platform-specific isn't available, default to iOS-like animations and styling
- **Navigation Extensions**: Use `context.pushNative()`, `context.pushReplacementNative()`, `context.pushAndRemoveUntilNative()` for manual navigation
- **Never use**: Generic Flutter transitions, `showDialog`/`showModalBottomSheet` directly, non-native page routes, or `AnimatedSwitcher` without native transition builders

### User Interface Guidelines
- **Bottom Sheets Over Dialogs**: Always use styled bottom sheets instead of dialogs for confirmations, options, and forms
- **Confirmation Pattern**: Use `ConfirmationBottomSheet.show()` with loading states and clear messaging
- **Modal Presentations**: Custom styled bottom sheets with handle bars, proper spacing, and consistent design
- **Interactive Elements**: Clear button hierarchy, proper touch targets, and loading indicators during async operations

### Native Navigation Utilities Reference
All utilities are located in `lib/common/navigation/native_page_route.dart`:

**Route Creation:**
- **NativePageRoute<T>**: Custom page route with platform-specific transitions
- **NativeTransitions.page()**: For GoRouter page builders with native transitions
- **NativeTransitions.buildPageTransition()**: For AnimatedSwitcher/in-flow transitions with platform-native animations

**Modal Presentations:**
- **NativeTransitions.showNativeModalBottomSheet()**: Platform-specific bottom sheets (Cupertino on iOS, Material on Android)
- **NativeTransitions.showNativeDialog()**: Platform-specific dialog presentations

**Navigation Extensions:**
- **context.pushNative()**: Push a new screen with native transitions
- **context.pushReplacementNative()**: Replace current screen with native transitions
- **context.pushAndRemoveUntilNative()**: Push and remove all previous routes with native transitions

**Implementation Example:**
```dart
// GoRouter route
GoRoute(
  path: '/example',
  pageBuilder: (context, state) => NativeTransitions.page(
    child: const ExampleScreen(),
    key: state.pageKey,
  ),
)

// AnimatedSwitcher (onboarding, wizards)
AnimatedSwitcher(
  duration: Platform.isIOS ? Duration(milliseconds: 350) : Duration(milliseconds: 300),
  transitionBuilder: (child, animation) {
    return NativeTransitions.buildPageTransition(
      child: child,
      animation: animation,
      secondaryAnimation: AlwaysStoppedAnimation(0.0),
      isForward: true,
    );
  },
  child: currentStepWidget,
)
```

### Standard Layout Pattern for Forms and Detail Views
For any screen with scrollable content and a primary action button (forms, settings, detail views), ALWAYS use this pattern:

**Layout Structure:**
```dart
Scaffold(
  appBar: AppBar(...),
  body: Column(
    children: [
      // 1. Scrollable content area
      Expanded(
        child: SingleChildScrollView(  // or ListView
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              // Your content here
            ],
          ),
        ),
      ),

      // 2. Fixed button at bottom
      Padding(
        padding: EdgeInsets.fromLTRB(
          24.0,
          0.0,
          24.0,
          MediaQuery.of(context).padding.bottom + 16.0,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton(
            onPressed: isLoading || !canSave ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E5EA),
              disabledForegroundColor: const Color(0xFF8E8E93),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Button Text',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    ],
  ),
)
```

**Key Requirements:**
- Button height: exactly 62px
- Button border radius: 16px
- Button is full width (`double.infinity`)
- Horizontal padding from edges: 24px
- Bottom padding: `MediaQuery.of(context).padding.bottom + 16.0` (respects safe area)
- Disabled colors: background `#E5E5EA`, text `#8E8E93`
- Loading indicator: 16px white CircularProgressIndicator with strokeWidth 2
- Text style: fontSize 18, fontWeight w600
- Use `Expanded` + `SingleChildScrollView`/`ListView` for scrollable content
- Content padding: `EdgeInsets.fromLTRB(20, 20, 20, 24)` (no bottom padding needed for button overlap)

**Examples:**
- Onboarding steps (username_step.dart, profile_details_step.dart, etc.)
- Edit profile screen
- Any form with save/submit button
- Settings screens with apply button

### App Lifecycle & Data Refresh

**IMPORTANT**: The app automatically refreshes friends data when resumed from background to keep notification badges up-to-date.

**Implementation** (`lib/main.dart`):
- Uses `WidgetsBindingObserver` to listen for app lifecycle changes
- On `AppLifecycleState.resumed`, calls `FriendsService.loadAllData()`
- This ensures the profile tab notification badge shows the latest friend request count

**Notification Badge** (`lib/screens/home_screen.dart`):
- Profile tab displays a red badge when there are pending friend requests
- Badge count is reactive: `context.watch<FriendsService>().pendingRequestsCount`
- Badge shows "9+" for 10 or more requests
- Badge automatically updates when friends data changes

**When Friends Data Refreshes:**
1. ✅ App resumes from background (main.dart lifecycle observer)
2. ✅ User navigates to a public profile (public_profile_screen.dart)
3. ✅ User accepts/declines a friend request (friends_screen.dart)
4. ✅ User sends a friend request (friends_screen.dart, public_profile_screen.dart)
5. ✅ App first loads (home_screen.dart initState)

### Type Safety: Use Enums Instead of Hardcoded Strings

**CRITICAL**: Never use hardcoded strings for status values, types, or enums. Always use type-safe enums defined in the models.

**Friendship Status Example:**

**❌ WRONG (Hardcoded strings):**
```dart
if (user.friendshipStatus == 'accepted') { ... }
if (request.status == 'pending') { ... }
getFriendRequests(type: 'sent')
_respondToRequest(request, 'decline')
```

**✅ CORRECT (Using enums and model getters):**
```dart
// Use model getters for boolean checks
if (user.isFriend) { ... }
if (request.isPending) { ... }

// Use enums when creating instances or calling APIs
getFriendRequests(type: FriendRequestType.sent.toJson())
_respondToRequest(request, FriendRequestAction.decline.toJson())

// Use enums for creating model instances
UserSearchResult(
  friendshipStatus: FriendshipStatus.pending.toJson(),
  requestDirection: RequestDirection.sent.toJson(),
)
```

**Available Friendship Enums** (defined in `lib/models/friendship_enums.dart`):
- `FriendshipStatus` - none, pending, accepted, declined
- `RequestDirection` - none, sent, received
- `FriendRequestType` - sent, received (for API filter parameters)
- `FriendRequestAction` - accept, decline (for responding to requests)

**Model Getters Available:**
- `UserSearchResult`: `isFriend`, `hasPendingRequest`, `requestSentByMe`, `requestSentToMe`, `status`, `direction`
- `UserProfile`: `isFriend`, `hasPendingRequest`, `requestSentByMe`, `requestSentToMe`, `status`, `direction`
- `FriendRequest`: `isPending`, `isAccepted`, `isDeclined`, `requestStatus`
- `Friend`: `friendshipStatus`, `isActive`

**Benefits:**
1. **Type Safety**: Catch errors at compile-time instead of runtime
2. **IDE Support**: Autocomplete and refactoring work correctly
3. **Consistency**: Single source of truth for all status values
4. **Maintainability**: Easy to add/rename statuses across the entire codebase
5. **Self-Documenting**: Enum names are clear and descriptive

**When Adding New Status Types:**
1. Create enum in appropriate models file (or create new enums file)
2. Add `toJson()` method for API communication
3. Add `fromJson()` static method for parsing API responses
4. Add boolean helper getters to relevant models
5. Update all hardcoded strings throughout the codebase

## TODO Before Release

### Backend Setup
- **Database Migration**: Run initial schema migration on production database
- **Environment Variables**: Configure all production environment variables
- **Firebase Service Account**: Set up production Firebase service account key
- **Cloudflare R2**: Configure production R2 bucket and access keys
- **SSL/HTTPS**: Ensure all API connections use HTTPS in production

### Firebase Configuration for Production
- **Android Google Sign-in**: Generate SHA-1 fingerprint for production release key and update Firebase configuration
  - Generate release keystore: `keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000`
  - Get SHA-1 fingerprint: `keytool -list -v -keystore release-key.keystore -alias release`
  - Add SHA-1 to Firebase Project Settings > Your apps > Android app
  - Download and replace `google-services.json` file
  - Required for Google Sign-in to work in production builds

### Enhanced Onboarding System
- **Contact Book Integration**: Implement contact book access and phone number validation for friend discovery
- **Friend Finding Service**: Create backend API endpoint to match phone numbers with existing users
- **Phone Number Storage**: Add phone_number field to users table with proper indexing for fast lookups
- **Privacy Controls**: Implement user privacy settings for phone number visibility and friend discovery
- **Username Availability**: Implement real-time username availability checking during onboarding
- **Birthday & Gender Fields**: Add birthday and gender fields to user profile with proper validation
- **Notification Preferences**: Implement granular notification settings for birthdays, coupons, and discounts
