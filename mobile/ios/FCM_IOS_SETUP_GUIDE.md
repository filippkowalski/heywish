# iOS Firebase Cloud Messaging (FCM) Setup Guide

This guide will help you set up push notifications for HeyWish on iOS using Firebase Cloud Messaging (FCM).

---

## 📋 Current Status

### ✅ Already Configured
- `firebase_messaging` package installed (v15.1.4)
- `GoogleService-Info.plist` configured
- Notification permission description added to Info.plist
- App Groups capability enabled

### ⚠️ Needs Manual Configuration
- Push Notifications capability in Xcode
- APNs authentication key upload to Firebase Console (for production)

---

## 🚀 Step 1: Enable Push Notifications Capability in Xcode

### Instructions:

1. **Open the project in Xcode:**
   ```bash
   cd /Users/filip.zapper/Workspace/heywish/mobile/ios
   open Runner.xcworkspace
   ```

2. **Select Runner target:**
   - Click on **Runner** (blue icon) in the left navigator
   - Under **TARGETS**, select **Runner**

3. **Go to Signing & Capabilities tab**

4. **Add Push Notifications capability:**
   - Click the **+ Capability** button (top left)
   - Type "Push Notifications" in the search
   - Double-click **Push Notifications** to add it

5. **Verify:**
   - You should see "Push Notifications" listed under Signing & Capabilities
   - No errors or warnings should appear

✅ **Step 1 Complete!**

---

## 🚀 Step 2: Code Configuration (Already Done!)

The following files have been updated automatically:

### Updated Files:
1. **AppDelegate.swift** - FCM registration and token handling
2. **Info.plist** - Background modes for remote notifications
3. **Runner.entitlements** - Push notifications entitlement

---

## 🚀 Step 3: Testing FCM (Development)

### Test on Simulator (Limited):
```bash
flutter run
```

**Note:** iOS Simulator has limited push notification support. For full testing, use a physical device.

### Test on Physical Device:
```bash
flutter run -d <your-device-name>
```

### Verify Setup:
1. Run the app on a physical device
2. Accept notification permissions when prompted
3. Check console logs for FCM token:
   ```
   FCM Token: <your-token-here>
   ```
4. Copy this token to test sending notifications from Firebase Console

---

## 🚀 Step 4: Production Setup (APNs Authentication Key)

### Why You Need This:
For **production** push notifications, you must upload an APNs authentication key to Firebase.

### Instructions:

#### 4A: Generate APNs Authentication Key (Apple Developer Portal)

1. **Go to Apple Developer Portal:**
   - Visit: https://developer.apple.com/account/resources/authkeys/list
   - Sign in with your Apple Developer account

2. **Create a new key:**
   - Click the **+ button** (or "Create a key")
   - **Key Name:** `HeyWish FCM Key` (or any descriptive name)
   - **Enable:** Check the box for **Apple Push Notifications service (APNs)**
   - Click **Continue**

3. **Download the key:**
   - Click **Download** to download the `.p8` file
   - **⚠️ IMPORTANT:** Save this file securely! You can only download it once!
   - Note down:
     - **Key ID** (e.g., `ABC123XYZ4`)
     - **Team ID** (found in top-right corner of the page)

4. **Click Done**

#### 4B: Upload APNs Key to Firebase Console

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com
   - Select your **HeyWish** project

2. **Navigate to Project Settings:**
   - Click the ⚙️ (gear icon) next to "Project Overview"
   - Select **Project Settings**

3. **Go to Cloud Messaging tab:**
   - Click the **Cloud Messaging** tab

4. **Scroll to "Apple app configuration":**
   - Under **iOS app configuration**, find the APNs section

5. **Upload APNs Authentication Key:**
   - Click **Upload** button
   - Select your `.p8` file
   - Enter:
     - **Key ID** (from step 4A)
     - **Team ID** (from step 4A)
   - Click **Save**

✅ **APNs Key Configured!**

---

## 🧪 Testing Push Notifications

### Option 1: Firebase Console (Simple)

1. Go to Firebase Console → **Messaging**
2. Click **"Create your first campaign"** or **"New campaign"**
3. Select **"Firebase Notification messages"**
4. Fill in:
   - **Notification title:** "Test from HeyWish"
   - **Notification text:** "This is a test notification"
5. Click **Next**
6. Select your iOS app
7. Click **Review** → **Publish**

### Option 2: Using FCM Token (Advanced)

Send a test notification using curl:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test from HeyWish",
      "body": "This is a test notification"
    }
  }'
```

Replace:
- `YOUR_SERVER_KEY`: Found in Firebase Console → Project Settings → Cloud Messaging → Server key
- `DEVICE_FCM_TOKEN`: The token logged in the console when you run the app

---

## 🔧 Troubleshooting

### Issue: No FCM token printed in console

**Solutions:**
1. Make sure you're running on a **physical device** (simulator has limited support)
2. Check that you accepted notification permissions
3. Verify GoogleService-Info.plist is in the project
4. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Issue: Notifications not received

**Solutions:**
1. **Check notification permissions:**
   - Settings → HeyWish → Notifications → Allow Notifications (ON)
2. **Verify APNs key is uploaded** (for production)
3. **Check app is in background** (some notifications only show in background)
4. **Verify device has internet connection**

### Issue: "Mismatched Sender ID" error

**Solutions:**
1. Delete and reinstall the app
2. Verify GoogleService-Info.plist is correct
3. Clean build folder and rebuild

---

## 📱 Notification Handling in Your App

The FCM setup is complete! Now you can handle notifications in your Dart code:

### Listen for Messages (Foreground):

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got a message whilst in the foreground!');
  print('Message data: ${message.data}');

  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
});
```

### Handle Background Messages:

```dart
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}
```

### Get FCM Token:

```dart
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

---

## ✅ Verification Checklist

Go through this checklist to ensure everything is set up correctly:

- [ ] Push Notifications capability added to Runner target in Xcode
- [ ] App runs without errors (flutter run)
- [ ] FCM token is printed in console
- [ ] Notification permissions requested on app launch
- [ ] User accepts notification permissions
- [ ] Test notification received from Firebase Console
- [ ] APNs authentication key uploaded (for production)
- [ ] Notifications work in both foreground and background

---

## 🎉 Success Criteria

You'll know FCM is working when:

1. ✅ App requests notification permissions on first launch
2. ✅ FCM token is printed in console/logs
3. ✅ Test notification sent from Firebase Console is received
4. ✅ Tapping notification opens the app
5. ✅ Background notifications show in notification center

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Messaging Package](https://firebase.flutter.dev/docs/messaging/overview)
- [Apple Push Notifications Service](https://developer.apple.com/documentation/usernotifications)
- [Testing FCM](https://firebase.google.com/docs/cloud-messaging/ios/first-message)

---

**Setup Time:** 15-20 minutes
**Difficulty Level:** Intermediate

**Need help?** Check the troubleshooting section or refer to the official Firebase documentation.
