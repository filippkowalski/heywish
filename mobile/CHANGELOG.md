# Changelog

All notable changes to the Jinnie mobile app will be documented in this file.

## Instructions for Claude Code

When adding entries to this changelog:
1. **Always add new entries at the top** (below this instruction block, before older versions)
2. **Version Format**: Use semantic versioning (MAJOR.MINOR.PATCH+BUILD_NUMBER)
   - MAJOR: Breaking changes or complete overhauls
   - MINOR: New features, significant improvements
   - PATCH: Bug fixes, minor improvements
   - BUILD_NUMBER: Increment for each release (iOS/Android build number)
3. **Date Format**: Use ISO 8601 format (YYYY-MM-DD)
4. **Categories**: Group changes under these headings:
   - **🎉 New Features** - New functionality added
   - **✨ Improvements** - Enhancements to existing features
   - **🐛 Bug Fixes** - Issues resolved
   - **🔧 Technical** - Infrastructure, dependencies, build system
   - **📱 Platform Specific** - iOS or Android specific changes
   - **🔒 Security** - Security-related changes
   - **⚠️ Breaking Changes** - Changes that require user action or break compatibility
5. **Writing Style**:
   - Use present tense ("Add feature" not "Added feature")
   - Be specific and concise
   - Include relevant context when necessary
   - Reference issue numbers if applicable
6. **Release Checklist**:
   - Update version in `pubspec.yaml` (version: X.Y.Z+BUILD)
   - Document all changes since last release
   - Update Firebase configuration if Google Sign-in changed (see CLAUDE.md)
   - Test on both iOS and Android
   - Build release: `flutter build appbundle` and `flutter build ios --release`

---

## [Unreleased]

---

## [1.13.0+30] - 2025-11-21

### 🎉 New Features

**Smart Clipboard Paste** (2025-01-21)
- Unified "Paste" button intelligently detects content type (images, URLs, text)
- Automatically identifies image URLs from Google Images, Imgur, Flickr, and other hosting services
- HTTP Content-Type checking for reliable image detection
- Supports pasting actual clipboard images on both iOS and Android
- Silent, seamless operation with no feedback messages

**iOS Share Extension Improvements** (2025-01-21)
- Share images from Photos and other apps directly to Jinnie
- Prioritized image handling over URL references
- Proper image file persistence after share extension closes
- Seamless integration with system share sheet

### ✨ Improvements

**Enhanced Image Sharing** (2025-01-21)
- Share wishes with images from within the app
- Downloads and shares actual image files, not just URLs
- Works consistently on both iOS and Android
- Graceful fallback to text-only sharing if image fails

**Bottom Sheet Navigation** (2025-01-21)
- Fixed AddWishScreen to consistently show as bottom sheet
- Improved deeplink handling to show bottom sheet instead of full-page route
- Share extension now shows bottom sheet for consistent UX
- Better navigation stack management

**Wish Detail Screen** (2025-01-21)
- Fixed menu button visibility for wishes without images
- Improved layout spacing and touch targets
- Better visual hierarchy with consistent button placement

### 🐛 Bug Fixes

**Onboarding Flow** (2025-01-21)
- Removed redundant loader in flow screen
- Smoother transition between onboarding steps

**Web Dashboard** (2025-01-21)
- Prevent infinite wishlists fetch loop
- Improved bulk wish import with smart image fallback
- Better error handling for image URLs

**Fastlane iOS Upload** (2025-01-21)
- Fixed API key path resolution for iOS upload
- Improved authentication handling

### 🔧 Technical

**Clipboard Integration** (2025-01-21)
- Added platform-specific method channels for clipboard image access
- iOS: UIPasteboard integration with proper temp file handling
- Android: ClipboardManager integration with image URI support
- No permission dialogs - user-initiated actions only

**Image URL Detection** (2025-01-21)
- Pattern matching for known image hosting domains
- HTTP HEAD requests for Content-Type verification
- 3-second timeout for fast response
- Comprehensive support for image formats (JPG, PNG, GIF, WebP, BMP)

### 🎉 Previous Features from Earlier Builds

**Automatic Data Refresh After Account Merge** (2025-01-05)
- App now automatically refreshes wishlists and wishes after successful account merge
- Users see merged content immediately without manual refresh
- Implemented using reactive timestamp-based detection pattern
- See `AUTHENTICATION.md` for detailed technical documentation

**Enhanced Merge Detection** (2025-01-05)
- Hybrid merge detection: checks server API first, falls back to local SQLite
- Prevents data loss in both online and offline scenarios
- Catches server-only wishes that haven't synced to local database yet
- Gracefully handles network failures during merge detection

**Analytics Integration** (2025-01-05)
- Integrated Mixpanel for comprehensive analytics tracking
- Onboarding funnel tracking with step completion metrics
- User authentication method tracking (Google, Apple, Email)
- Profile completion tracking with customizable user properties
- Shopping interests and notification preference tracking

**Apple Sign-In Fix** (2025-01-05)
- Fixed "Invalid OAuth response from apple.com" error
- Added missing `accessToken` parameter to OAuth credential
- Apple Sign-In now works reliably on both iOS devices and simulator

**Anonymous Wish Data Loss Fix** (2025-01-05)
- Fixed issue where anonymous wishes disappeared after signing into existing account
- Merge detection now queries server while still authenticated as anonymous user
- Offline fallback ensures local-only data is also detected for merge

**Authentication System Documentation** (2025-01-05)
- Created comprehensive `AUTHENTICATION.md` documentation
- Covers all authentication flows, account merging, and data refresh
- Includes technical implementation details and troubleshooting guide
- Documents hybrid merge detection algorithm and design decisions

---

## [1.0.0+1] - 2025-10-23

### 🎉 Initial Release

This is the first production release of Jinnie - a modern, social-first wishlist platform.

#### Core Features

**Authentication & User Management**
- Firebase authentication with multiple providers (Google, Apple, Email/Password)
- Anonymous authentication with account linking
- Comprehensive 7-step onboarding flow (username, profile, notifications, discovery, account creation)
- User profile management with avatar upload
- Account settings and privacy controls

**Wishlist Management**
- Create and manage multiple wishlists
- Add wishes with images, descriptions, URLs, and price
- URL scraping for automatic wish details extraction
- Image upload to Cloudflare R2 storage
- Wish editing and deletion
- Wishlist sharing via unique URLs
- Public/private wishlist visibility settings

**Social Features**
- Friend system with requests and acceptance flow
- Activity feed showing friend actions
- Friend wishlist discovery
- Contact book integration for finding friends
- User search functionality

**Wish Reservation System**
- Reserve wishes on friends' lists
- Reservation management (view, cancel)
- Email-based anonymous reservations for non-users
- Reservation notifications

**Offline Support**
- SQLite local database for offline-first architecture
- Background sync when connectivity restored
- Optimistic UI updates
- Cached images for offline viewing

**UI/UX**
- Material Design 3 components
- Native platform transitions (iOS Cupertino, Android Material)
- Skeleton loading states
- Bottom sheets for confirmations and actions
- Pull-to-refresh functionality
- Custom styled bottom sheets
- Multi-language support with easy_localization

**Additional Features**
- Receive sharing intent integration (share from other apps)
- Quick actions for home screen shortcuts
- Push notifications via Firebase Cloud Messaging
- Screenshot detection for security
- App version info and update prompts
- Share wishlists and wishes
- Deep linking support

#### Platform Support
- **iOS**: Minimum iOS 13.0, optimized for iOS 18
- **Android**: Minimum SDK 23 (Android 6.0), target SDK 34

#### Technical Stack
- Flutter 3.7.2+
- Firebase (Auth, Analytics, Messaging)
- SQLite for local storage
- Cloudflare R2 for image storage
- GoRouter for navigation
- Provider for state management

#### Security
- Flutter secure storage for sensitive data
- Firebase App Check for backend security
- Keystore signing for Android releases
- Code signing for iOS releases

### 🔧 Build Configuration

**Android**
- Release keystore configured with SHA-1 fingerprint: `1E:68:D4:7B:94:EF:AA:9B:F5:9B:7C:82:D9:95:3C:5F:52:F4:69:2F`
- App bundle built and signed for Google Play Store
- Package name: `com.wishlists.gifts`

**iOS**
- Xcode project configured for release builds
- App icons added for all required sizes
- Signing configured (manual/automatic based on team setup)
- Bundle identifier: `com.wishlists.gifts`

### 📝 Known Issues
- None in this release

### 🔮 Coming Soon
- Birthday and gender fields in user profiles
- Enhanced notification preferences (birthdays, coupons, discounts)
- Real-time username availability checking
- Contact-based friend discovery with phone numbers
- Enhanced privacy controls

---

## Firebase Configuration Notes

**Important**: When generating production release keys for Android:
1. Generate release keystore: `keytool -genkey -v -keystore jinnie-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias jinnie-release`
2. Get SHA-1 fingerprint: `keytool -list -v -keystore jinnie-release-key.jks -alias jinnie-release`
3. Add SHA-1 to Firebase Console: Project Settings > Your apps > Android app
4. Download updated `google-services.json`
5. Replace file in `android/app/google-services.json`

This is required for Google Sign-in to work in production builds.

---

**Release SHA-1 Fingerprint**: `1E:68:D4:7B:94:EF:AA:9B:F5:9B:7C:82:D9:95:3C:5F:52:F4:69:2F`
