import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase will be initialized by Flutter using firebase_options.dart
    // DO NOT call FirebaseApp.configure() here to avoid double initialization

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Set up notification center delegate and FCM delegate
    // BUT DO NOT request permissions here - let Flutter handle it during onboarding
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Set FCM messaging delegate
    Messaging.messaging().delegate = self

    // Set up share extension method channel
    if let controller = window?.rootViewController as? FlutterViewController {
      let shareChannel = FlutterMethodChannel(name: "com.wishlists.gifts/share",
                                        binaryMessenger: controller.binaryMessenger)
      shareChannel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "getSharedContent" {
          self?.getSharedContent(result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      // Set up clipboard method channel
      let clipboardChannel = FlutterMethodChannel(name: "com.wishlists.gifts/clipboard",
                                        binaryMessenger: controller.binaryMessenger)
      clipboardChannel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "getClipboardImage" {
          self?.getClipboardImage(result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // Note: We don't call registerForRemoteNotifications() here
    // It will be called automatically when Flutter requests permissions during onboarding

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getSharedContent(result: FlutterResult) {
    let appGroupId = "group.com.wishlists.gifts"
    let sharedKey = "JinnieSharedContent"

    guard let userDefaults = UserDefaults(suiteName: appGroupId),
          let sharedData = userDefaults.dictionary(forKey: sharedKey) else {
      print("⚠️ No shared content found")
      result(nil)
      return
    }

    print("✅ Retrieved shared content: \(sharedData)")

    // Clear the shared data after reading
    userDefaults.removeObject(forKey: sharedKey)
    userDefaults.synchronize()

    result(sharedData)
  }

  private func getClipboardImage(result: FlutterResult) {
    // Check if clipboard has an image
    guard let image = UIPasteboard.general.image else {
      print("⚠️ No image in clipboard")
      result(nil)
      return
    }

    // Save image to temporary directory
    let fileName = "clipboard_\(Date().timeIntervalSince1970).jpg"
    let tempDir = FileManager.default.temporaryDirectory
    let fileURL = tempDir.appendingPathComponent(fileName)

    guard let imageData = image.jpegData(compressionQuality: 0.85) else {
      print("❌ Failed to convert image to JPEG")
      result(nil)
      return
    }

    do {
      try imageData.write(to: fileURL)
      print("✅ Clipboard image saved to: \(fileURL.path)")
      result(fileURL.path)
    } catch {
      print("❌ Error saving clipboard image: \(error)")
      result(nil)
    }
  }

  // Handle APNs token registration
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅ APNs token registered")
    Messaging.messaging().apnsToken = deviceToken
  }

  // Handle APNs registration failure
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Failed to register for remote notifications: \(error)")
  }

  // Handle URL schemes (e.g., from share extension)
  override func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    print("📱 URL opened: \(url.absoluteString)")

    // Check if it's from share extension
    if url.scheme == "jinnie" && url.host == "share" {
      print("✅ Share extension URL detected")

      // Retrieve shared data from App Group
      let appGroupId = "group.com.wishlists.gifts"
      let sharedKey = "JinnieSharedContent"

      if let userDefaults = UserDefaults(suiteName: appGroupId),
         let sharedData = userDefaults.dictionary(forKey: sharedKey) {
        print("✅ Retrieved shared data: \(sharedData)")

        // Send to Flutter via MethodChannel
        if let controller = window?.rootViewController as? FlutterViewController {
          let channel = FlutterMethodChannel(name: "com.wishlists.gifts/share",
                                            binaryMessenger: controller.binaryMessenger)
          channel.invokeMethod("handleSharedContent", arguments: sharedData)
          print("✅ Sent shared data to Flutter")
        }

        // Clear the shared data after processing
        userDefaults.removeObject(forKey: sharedKey)
        userDefaults.synchronize()
      } else {
        print("⚠️ No shared data found in App Group")
      }

      return true
    }

    return super.application(app, open: url, options: options)
  }
}

// MARK: - FCM Messaging Delegate
extension AppDelegate: MessagingDelegate {
  // Handle FCM token refresh
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("📱 FCM Token: \(fcmToken ?? "nil")")

    // Send token to your backend server if needed
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
