# Firebase Crashlytics Testing Guide

This guide helps you verify that Firebase Crashlytics is properly integrated and working in the Jinnie mobile app.

## Prerequisites

1. **Firebase Project Setup**: Ensure your Firebase project has Crashlytics enabled in the Firebase Console.
2. **Build for Release Mode**: Crashlytics works best in release mode or on real devices.
3. **Internet Connection**: Device needs internet to send crash reports to Firebase.

## Testing Methods

### 1. Test Crash (Force Crash)

To verify Crashlytics is working, you can trigger a test crash:

**Option A: Using Debug Menu (Recommended)**
Add a debug button in your app's settings or profile screen:

```dart
if (kDebugMode) {
  ElevatedButton(
    onPressed: () {
      CrashlyticsLogger.testCrash();
    },
    child: Text('Test Crashlytics (Debug Only)'),
  ),
}
```

**Option B: Using Flutter DevTools Console**
```dart
import 'package:jinnie/utils/crashlytics_logger.dart';

// Run this in DevTools console:
CrashlyticsLogger.testCrash();
```

### 2. Test Non-Fatal Error Logging

Test that non-fatal errors are being logged:

```dart
// Test logging an error
try {
  throw Exception('Test error for Crashlytics');
} catch (e, stackTrace) {
  await CrashlyticsLogger.logError(
    e,
    stackTrace,
    reason: 'Testing Crashlytics error logging',
    context: {
      'test_type': 'manual_test',
      'timestamp': DateTime.now().toString(),
    },
  );
}
```

### 3. Test Automatic Error Catching

The following errors are automatically logged to Crashlytics:

1. **Flutter Framework Errors**: Any uncaught exception in Flutter widgets
2. **Async Errors**: Errors in async operations outside Flutter's error handling
3. **API Errors**: Network errors with 5xx status codes or timeouts
4. **Authentication Errors**: Failed auth sync attempts after retries

To test, you can:
- Try to access an invalid API endpoint
- Trigger a network timeout by using airplane mode during an API call
- Cause a widget rendering error

### 4. Test User Identification

When a user authenticates, their Firebase UID is automatically set in Crashlytics:

1. Sign in with Google/Apple/Email
2. Check Firebase Console → Crashlytics → Crashes/Non-fatals
3. Click on any crash/error
4. Verify that the User ID is set

## Verifying Crashlytics in Firebase Console

1. **Navigate to Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your Jinnie project
   - Click on "Crashlytics" in the left menu

2. **Check for Test Crashes**
   - Crashes may take 5-15 minutes to appear in the console
   - Refresh the page after triggering test crashes
   - Look for crashes with your device model/OS version

3. **Check Non-Fatal Errors**
   - Go to Crashlytics → Non-fatals
   - You should see logged errors with stack traces
   - Check that user IDs and custom keys are attached

## What Gets Logged Automatically

### 1. Authentication Events
- ✅ User sign-in (Google, Apple, Email)
- ✅ User sign-out
- ✅ Backend sync failures (after 3 retries)
- ✅ User ID set on authentication

### 2. API Errors
- ✅ Network timeouts
- ✅ Server errors (5xx)
- ✅ Connection errors
- ❌ Client errors (4xx) - Not logged (expected errors)

### 3. Critical Failures
- ✅ Flutter framework crashes
- ✅ Unhandled async errors
- ✅ Zone errors (errors outside Flutter's handling)

## Custom Context in Crash Reports

When crashes occur, the following custom data is included:

### From AuthService:
- `firebase_uid`: User's Firebase authentication ID
- `signup_method`: google, apple, email, or anonymous
- `attempts`: Number of retry attempts

### From ApiService:
- `error_type`: Type of Dio exception
- `status_code`: HTTP status code
- `path`: API endpoint path
- `method`: HTTP method (GET, POST, etc.)

## Best Practices

1. **Don't Overuse Test Crashes**: Only test crashes during development, not in production.
2. **Monitor Regularly**: Check Firebase Console weekly for new crash patterns.
3. **Act on Trends**: If you see repeated crashes, prioritize fixing them.
4. **Use Custom Keys**: Add relevant context when logging errors manually.
5. **Protect User Privacy**: Never log sensitive data (passwords, tokens, PII).

## Troubleshooting

### Crashes Not Appearing

1. **Wait 5-15 minutes**: Crashlytics batches reports.
2. **Check Internet Connection**: Device must be online.
3. **Verify Firebase Setup**: Ensure google-services.json (Android) and GoogleService-Info.plist (iOS) are up to date.
4. **Check Build Type**: Use release builds or real devices.

### User ID Not Set

- Verify user is authenticated before checking crashes
- Check that AuthService._onAuthStateChanged is being called
- Look for "User authenticated" in Crashlytics logs

### Custom Keys Not Appearing

- Ensure you're calling CrashlyticsLogger.setCustomKey before the crash
- Custom keys are attached to the next crash that occurs

## Example: Testing End-to-End

```dart
// 1. Sign in to set user ID
await authService.signInWithGoogle();

// 2. Add custom context
await CrashlyticsLogger.setCustomKey('test_phase', 'e2e_test');

// 3. Log a non-fatal error
try {
  throw Exception('E2E Test Error');
} catch (e, stackTrace) {
  await CrashlyticsLogger.logError(e, stackTrace, reason: 'E2E Test');
}

// 4. Wait 10 minutes, check Firebase Console

// 5. Trigger a crash (optional)
// CrashlyticsLogger.testCrash();
```

## Production Monitoring

Once deployed, monitor these key metrics in Firebase Console:

1. **Crash-Free Users %**: Target > 99%
2. **Crash-Free Sessions %**: Target > 99.5%
3. **Most Common Crashes**: Fix top 3 weekly
4. **New vs Recurring Issues**: Prioritize new issues
5. **Velocity**: Trend of crash rates over time

## Need Help?

- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [FlutterFire Crashlytics](https://firebase.flutter.dev/docs/crashlytics/overview)
