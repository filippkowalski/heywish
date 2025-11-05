# Deep Linking Implementation Guide

## Overview

Jinnie implements cross-platform deep linking to allow web users to seamlessly open user profiles in the mobile app. This document explains the complete architecture, configuration, and flows.

---

## Architecture Summary

### Component Overview

```
┌─────────────────────────────────────────────────┐
│           Web Profile Page                      │
│  ┌───────────────────────────────────────────┐  │
│  │  ProfileHeader (Follow Button)            │  │
│  │    ↓ onClick                              │  │
│  │  FollowDialog (Opens)                     │  │
│  │    ↓ Platform Detection                   │  │
│  │    ↓ Click "Open in Jinnie App"          │  │
│  └────┼──────────────────────────────────────┘  │
│       │                                          │
└───────┼──────────────────────────────────────────┘
        │
        ├─→ iOS: window.location.href = https://jinnie.app/@user/follow
        │     ↓
        │   Landing Page (Fallback Detection)
        │     ↓
        │   App Store (if not installed)
        │
        └─→ Android: window.location.href = intent://...
              ↓
            Intent Pattern (Automatic Fallback)
              ↓
            Play Store (if not installed)
```

---

## Platform-Specific Implementations

### iOS Universal Links

**How It Works:**
1. User clicks "Follow" button on web
2. Web navigates to `https://jinnie.app/@username/follow`
3. iOS checks Associated Domains configuration
4. If app installed: Opens app via universal link
5. If not installed: Loads web landing page → redirects to App Store

**Configuration Files:**

**iOS App** (`Runner.entitlements`):
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:jinnie.app</string>
    <string>applinks:www.jinnie.app</string>
</array>
```

**Web Server** (`.well-known/apple-app-site-association`):
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "474TK9U3BP.com.wishlists.gifts",
      "paths": ["/@*", "/@*/follow", "/*/follow"]
    }]
  }
}
```

**Requirements:**
- Must use HTTPS (not custom schemes)
- Must use top-level navigation (iOS 13+ blocks iframes)
- File must be accessible at `https://jinnie.app/.well-known/apple-app-site-association`
- No file extension, served as `application/json`

**Deep Link Handler** (`mobile/lib/services/deep_link_service.dart`):
```dart
const primaryHosts = {'jinnie.app', 'www.jinnie.app'};
const legacyFollowHosts = {'jinnie.co', 'www.jinnie.co'};

final host = uri.host.toLowerCase();
final isPrimaryHost =
    (uri.scheme == 'https' || uri.scheme == 'http') && primaryHosts.contains(host);
final isLegacyFollowLink =
    (uri.scheme == 'https' || uri.scheme == 'http') &&
    legacyFollowHosts.contains(host) &&
    uri.path.startsWith('/@');

if (isPrimaryHost || isLegacyFollowLink) {
  // Parse path: /@username/follow
  final followMatch = RegExp(r'^/@([^/]+)/follow$').firstMatch(path);
  if (followMatch != null) {
    final username = followMatch.group(1)!;
    _navigateToProfile(username, highlightFollow: true);
  }
}
```

---

### Android App Links

**How It Works:**
1. User clicks "Follow" button on web
2. Web navigates to Intent URL with embedded fallback
3. Android parses Intent URL pattern
4. If app installed: Opens app immediately
5. If not installed: Redirects to `browser_fallback_url` (Play Store)

**Configuration Files:**

**Android App** (`AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="jinnie.app"
        android:pathPrefix="/" />
    <data
        android:scheme="https"
        android:host="www.jinnie.app"
        android:pathPrefix="/" />
</intent-filter>
```

**Web Server** (`.well-known/assetlinks.json`):
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.wishlists.gifts",
    "sha256_cert_fingerprints": [
      "51:48:7D:7F:1A:EF:E4:5E:B9:85:7C:72:8A:58:18:38:17:8A:8F:0E:55:EC:F0:5B:E6:C3:BF:DE:1F:E0:21:B6",
      "AF:47:B2:DA:99:B6:8A:AE:60:00:C8:D2:D1:C4:83:F1:A1:51:22:3C:08:E2:9F:BC:E9:4E:F2:13:A4:47:91:A0"
    ]
  }
}]
```

**Intent URL Pattern** (Web dialog):
```typescript
const intentUrl =
  `intent://profile/${username}?action=follow#Intent;` +
  `scheme=com.wishlists.gifts;` +
  `package=com.wishlists.gifts;` +
  `S.browser_fallback_url=${encodeURIComponent(playStoreUrl)};` +
  `end;`;
```

**Requirements:**
- Intent URL format with scheme, package, and fallback
- SHA-256 fingerprints from both debug and release keystores
- File must be accessible at `https://jinnie.app/.well-known/assetlinks.json`
- `autoVerify="true"` in intent filter

**Deep Link Handler** (`mobile/lib/services/deep_link_service.dart`):
```dart
if (uri.scheme == 'com.wishlists.gifts') {
  // Parse path: profile/username
  if (uri.host == 'profile' || path.startsWith('profile/')) {
    final username = uri.host == 'profile' ? path : path.replaceFirst('profile/', '');
    _navigateToProfile(username, highlightFollow: uri.queryParameters['action'] == 'follow');
  }
}
```

---

## Web Implementation

### Follow Button Component

**Location:** `web/components/follow-button.client.tsx`

**Features:**
- Hidden when viewing own profile
- Visible for all other users (authenticated or not)
- Shadcn-style minimal design
- Plus icon with "Follow @username" text

**Usage:**
```tsx
<FollowButton
  username="john"
  userId="uuid-123"
  isOwnProfile={false}
  onFollowClick={() => setShowDialog(true)}
/>
```

---

### Follow Dialog Component

**Location:** `web/components/follow-dialog.client.tsx`

**Features:**
- Platform detection (iOS/Android/Desktop)
- User avatar display
- Primary CTA: "Open in Jinnie App"
- Secondary CTA: "Get Jinnie for [Platform]"
- Disabled until platform detected
- Lists benefits of following

**Platform-Specific Logic:**
```typescript
if (platform === 'ios') {
  // iOS: Universal link with landing page fallback
  window.location.href = `https://jinnie.app/@${username}/follow`;
} else if (platform === 'android') {
  // Android: Intent URL with automatic fallback
  window.location.href = intentUrl;
} else {
  // Desktop: Direct to app store
  window.location.href = appStoreUrl;
}
```

---

### Landing Page (iOS Fallback)

**Location:** `web/app/[username]/follow/page.tsx`

**Purpose:**
- Handles iOS universal link fallback when app not installed
- Detects if app opened via `visibilitychange` event
- Auto-redirects to App Store after 1.5s if app didn't open
- Shows loading UI: "Opening Jinnie..."

**Implementation:**
```typescript
useEffect(() => {
  let appOpened = false;

  const handleVisibilityChange = () => {
    if (document.hidden) {
      appOpened = true; // App opened
    }
  };

  document.addEventListener('visibilitychange', handleVisibilityChange);

  setTimeout(() => {
    if (!appOpened) {
      // Redirect to App Store
      window.location.href = appStoreUrl;
    }
  }, 1500);

  return () => {
    document.removeEventListener('visibilitychange', handleVisibilityChange);
  };
}, []);
```

**Why Needed:**
- iOS 13+ blocks universal links from iframes
- Requires top-level navigation
- Prevents 404 errors when app not installed
- Provides graceful fallback experience

---

## Mobile Implementation

### Deep Link Service

**Location:** `mobile/lib/services/deep_link_service.dart`

**Responsibilities:**
- Listen for incoming deep links (cold start + warm start)
- Parse universal links (HTTPS) and custom schemes
- Navigate to appropriate screens via GoRouter
- Handle query parameters (e.g., `?action=follow`)

**Initialization** (in `main.dart`):
```dart
final _deepLinkService = DeepLinkService();

@override
void initState() {
  super.initState();

  // Initialize after router setup
  Future.delayed(const Duration(milliseconds: 500), () {
    _deepLinkService.initialize(_router);
  });
}

@override
void dispose() {
  _deepLinkService.dispose();
  super.dispose();
}
```

**Supported URL Patterns:**
- `https://jinnie.app/@username/follow` → Navigate to profile
- `https://jinnie.app/@username` → Navigate to profile
- `com.wishlists.gifts://profile/username?action=follow` → Navigate to profile

**Navigation:**
```dart
void _navigateToProfile(String username, {bool highlightFollow = false}) {
  final route = '/profile/$username${highlightFollow ? '?highlight=follow' : ''}';
  _router!.go(route);
}
```

---

## Configuration Details

### iOS Configuration

**Team ID:** `474TK9U3BP`

**Xcode Setup:**
1. Open `Runner.xcodeproj` in Xcode
2. Select Runner target → Signing & Capabilities
3. Add "Associated Domains" capability
4. Add domains:
   - `applinks:jinnie.app`
   - `applinks:www.jinnie.app`

**Entitlements File:** `ios/Runner/Runner.entitlements`
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:jinnie.app</string>
    <string>applinks:www.jinnie.app</string>
</array>
```

**Web Server File:** Must be accessible at:
```
https://jinnie.app/.well-known/apple-app-site-association
```

---

### Android Configuration

**Package Name:** `com.wishlists.gifts`

**Debug Keystore Fingerprint:**
```
51:48:7D:7F:1A:EF:E4:5E:B9:85:7C:72:8A:58:18:38:17:8A:8F:0E:55:EC:F0:5B:E6:C3:BF:DE:1F:E0:21:B6
```

**Release Keystore Fingerprint:**
```
AF:47:B2:DA:99:B6:8A:AE:60:00:C8:D2:D1:C4:83:F1:A1:51:22:3C:08:E2:9F:BC:E9:4E:F2:13:A4:47:91:A0
```

**How to Get Fingerprints:**
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep "SHA256"

# Release keystore
keytool -list -v -keystore /path/to/release.keystore \
  -alias your-alias | grep "SHA256"
```

**Web Server File:** Must be accessible at:
```
https://jinnie.app/.well-known/assetlinks.json
```

---

## User Flows

### iOS - App Installed
```
1. User visits https://jinnie.app/@john
2. Clicks "Follow" button
3. Dialog opens: "Open in Jinnie App"
4. Clicks button
5. Navigates to: https://jinnie.app/@john/follow
6. iOS checks Associated Domains
7. ✅ App installed → Opens app immediately (< 0.5s)
8. DeepLinkService receives URL
9. Navigates to /profile/john in app
10. User can follow @john
```

### iOS - App NOT Installed
```
1. User visits https://jinnie.app/@john
2. Clicks "Follow" button
3. Dialog opens: "Open in Jinnie App"
4. Clicks button
5. Navigates to: https://jinnie.app/@john/follow
6. iOS checks Associated Domains
7. ❌ App not installed → Loads web page
8. Landing page shows: "Opening Jinnie..."
9. Page monitors visibilitychange (app didn't open)
10. After 1.5s → Redirects to App Store
11. User can download app
```

### Android - App Installed
```
1. User visits https://jinnie.app/@john
2. Clicks "Follow" button
3. Dialog opens: "Open in Jinnie App"
4. Clicks button
5. Navigates to universal link https://jinnie.app/@john/follow
6. Android verifies App Link
7. ✅ App installed → Opens app immediately
8. DeepLinkService receives universal link URL
9. Navigates to /profile/john in app
10. User can follow @john
```

### Android - App NOT Installed
```
1. User visits https://jinnie.app/@john
2. Clicks "Follow" button
3. Dialog opens: "Open in Jinnie App"
4. Clicks button
5. Navigates to universal link https://jinnie.app/@john/follow
6. Android attempts to open app via App Link
7. ❌ App not installed → Link remains in browser
8. After timeout, web dialog redirects to Play Store
9. User can download app
```

### Desktop
```
1. User visits https://jinnie.app/@john
2. Clicks "Follow" button
3. Dialog opens: "Open in Jinnie App"
4. Clicks button
5. Platform detected as desktop
6. Immediately redirects to app store landing page
7. User sees download options for iOS/Android
```

---

## Testing & Verification

### iOS Testing

**Verify Configuration:**
```bash
# Check file is accessible
curl https://jinnie.app/.well-known/apple-app-site-association

# Expected: JSON with Team ID 474TK9U3BP
```

**Test Universal Links:**
```bash
# iOS Simulator
xcrun simctl openurl booted "https://jinnie.app/@testuser/follow"

# Should open app if installed, Safari if not
```

**Test on Device:**
1. Send link via Messages/Mail
2. Tap link (should open app, not Safari)
3. Long press → Should show "Open in Jinnie"

---

### Android Testing

**Verify Configuration:**
```bash
# Check file is accessible
curl https://jinnie.app/.well-known/assetlinks.json

# Expected: JSON with SHA-256 fingerprints
```

**Test App Links:**
```bash
# Test on device/emulator
adb shell am start -a android.intent.action.VIEW \
  -d "https://jinnie.app/@testuser/follow"

# Check verification status
adb shell pm get-app-links com.wishlists.gifts
# Should show: verified for jinnie.app
```

**Test Intent URLs:**
```bash
# Test Intent URL pattern
adb shell am start -a android.intent.action.VIEW \
  -d "intent://profile/testuser?action=follow#Intent;scheme=com.wishlists.gifts;package=com.wishlists.gifts;end;"
```

---

### Manual Testing Checklist

**iOS:**
- [ ] App installed: Tap link → App opens immediately
- [ ] App NOT installed: Tap link → Landing page → App Store
- [ ] Universal links work from: Safari, Messages, Mail, Notes
- [ ] No "Open in Safari" banner shown

**Android:**
- [ ] App installed: Tap link → App opens immediately
- [ ] App NOT installed: Tap link → Play Store immediately
- [ ] No "No app to open this link" dialog
- [ ] Works from: Chrome, Gmail, Messages

**Both:**
- [ ] Profile loads correctly in app
- [ ] Follow button visible on profile
- [ ] Deep link parameters preserved
- [ ] No crashes or errors

---

## Troubleshooting

### iOS Issues

**Universal links not working:**
1. Verify Associated Domains in Xcode
2. Check `.well-known` file is accessible via HTTPS
3. Verify Team ID matches Xcode project
4. Delete and reinstall app (iOS caches configuration)
5. Check device Settings → [App] → Default Browser App

**Landing page not loading:**
1. Verify route exists: `app/[username]/follow/page.tsx`
2. Check build includes new route
3. Test URL directly in Safari

---

### Android Issues

**App Links not verified:**
```bash
# Check verification status
adb shell pm get-app-links com.wishlists.gifts

# If not verified, check:
# 1. assetlinks.json accessible
# 2. SHA-256 fingerprints correct
# 3. android:autoVerify="true" in manifest
```

**Intent URL not working:**
1. Verify scheme matches manifest: `com.wishlists.gifts`
2. Check package name is correct
3. Verify fallback URL is encoded
4. Test on Chrome (best support for Intent URLs)

---

### Common Issues

**"No route found" in app:**
- Check DeepLinkService is initialized
- Verify GoRouter has `/profile/:username` route
- Check deep link handler regex patterns

**Platform detection not working:**
- Check user agent parsing in `platform-detection.ts`
- Verify button is disabled until detection completes
- Test on actual devices (not just simulators)

**Deep link opens Safari/Chrome instead of app:**
- iOS: Verify Associated Domains capability
- Android: Check App Links verification status
- Both: Ensure app installed with same signing certificate

---

## Security Considerations

### What's Public (Safe to Share)

✅ **SHA-256 Fingerprints:**
- One-way cryptographic hashes
- Cannot be reversed to get private keys
- Designed to be public (Android requirement)
- Published in `.well-known/assetlinks.json`

✅ **Team ID:**
- Public identifier for Apple Developer account
- Used in `.well-known/apple-app-site-association`
- Cannot be used to sign apps

✅ **Package Names:**
- Public app identifiers
- Visible in Play Store URLs

### What's Private (Must Protect)

❌ **Private Keys:**
- Keystore files (`.jks`, `.keystore`)
- Must be in `.gitignore`
- Never commit to version control

❌ **Passwords:**
- `storePassword` in `key.properties`
- `keyPassword` in `key.properties`
- Keep in `.gitignore`

❌ **Signing Certificates:**
- The actual certificate files
- Used to sign app releases

**Verification:**
```bash
# Verify private files are gitignored
git check-ignore android/key.properties android/*.jks

# Should output both files (means they're ignored)
```

---

## Maintenance

### When to Update Configuration

**iOS:**
- Team ID changes (rare, only if switching Apple accounts)
- Domain changes (e.g., new domain or subdomain)
- Path patterns change

**Android:**
- New release keystore generated
- Package name changes (rare)
- Domain changes

### Monitoring

**Metrics to Track:**
1. Deep link success rate (app opened vs store redirect)
2. Platform distribution (iOS vs Android)
3. Time to app open (should be < 1s)
4. Fallback rate (landing page → app store)

**Logging:**
```dart
// Mobile: DeepLinkService logs all deep links
debugPrint('🔗 Deep link received: $uri');
debugPrint('✅ Navigating to: $route');
```

---

## References

**Apple:**
- [Universal Links Documentation](https://developer.apple.com/ios/universal-links/)
- [Associated Domains Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_associated-domains)

**Android:**
- [App Links Documentation](https://developer.android.com/training/app-links)
- [Digital Asset Links](https://developers.google.com/digital-asset-links)
- [Intent URLs](https://developer.chrome.com/docs/android/intents)

**Flutter:**
- [app_links Package](https://pub.dev/packages/app_links)
- [Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)

---

## Changelog

### Version 1.0.0 (2025-11-03)
- Initial implementation of Follow button with deep linking
- iOS universal links with landing page fallback
- Android Intent URLs with automatic fallback
- Cross-platform deep link handler in mobile app
- Complete configuration for production deployment

---

## Contributors

- Implemented by Claude Code
- Team ID: 474TK9U3BP
- Package: com.wishlists.gifts
