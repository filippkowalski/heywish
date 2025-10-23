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

### 🎉 New Features
- None yet

### ✨ Improvements
- None yet

### 🐛 Bug Fixes
- None yet

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
