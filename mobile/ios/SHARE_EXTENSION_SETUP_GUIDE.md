# iOS Share Extension Setup - Complete Step-by-Step Guide

This guide will help you set up the Share Extension for HeyWish, allowing users to share URLs and images from other apps (Safari, Photos, etc.) directly to HeyWish.

---

## 📋 Prerequisites

- Xcode 14.0 or later
- macOS with Xcode Command Line Tools installed
- HeyWish project already set up
- Apple Developer account (for device testing)

---

## 🚀 Part 1: Xcode Setup (15 minutes)

### Step 1: Open Project in Xcode

```bash
cd /Users/filip.zapper/Workspace/heywish/mobile/ios
open Runner.xcworkspace
```

**⚠️ Important:** Always open `Runner.xcworkspace`, NOT `Runner.xcodeproj`!

---

### Step 2: Create Share Extension Target

1. **In Xcode menu bar:**
   - Click `File` → `New` → `Target...`

2. **Select template:**
   - In the template window, search for "Share Extension"
   - Select **"Share Extension"** (under iOS section)
   - Click **Next**

   ![Share Extension Template](https://docs-assets.developer.apple.com/published/4f7cc3d15d/rendered2x-1632943640.png)

3. **Configure the target:**
   - **Product Name:** `ShareExtension`
   - **Team:** Select your development team
   - **Organization Name:** `HeyWish`
   - **Organization Identifier:** `com.wishlists`
   - **Bundle Identifier:** Will auto-fill as `com.wishlists.gifts.ShareExtension`
   - **Language:** `Swift` ⚠️ Important: Must be Swift!
   - **Project:** `Runner`
   - **Embed in Application:** `Runner`
   - Click **Finish**

4. **Scheme activation prompt:**
   - When prompted "Activate 'ShareExtension' scheme?", click **Cancel**
   - We want to keep using the Runner scheme for builds

**✅ Checkpoint:** You should now see a new folder `ShareExtension` in your Xcode project navigator with these files:
- `ShareViewController.swift`
- `Info.plist`
- `MainInterface.storyboard`

---

### Step 3: Configure Share Extension Target Settings

1. **Select the ShareExtension target:**
   - In Xcode, click on the **project name** (`Runner`) at the very top of the navigator
   - In the center pane under TARGETS, select **ShareExtension** (not Runner)

2. **General Tab:**
   - **Display Name:** Change to `HeyWish`
   - **Bundle Identifier:** Verify it's `com.wishlists.gifts.ShareExtension`
   - **Version:** Match with main app (1.0.0)
   - **Build:** Match with main app (1)
   - **Deployment Info:**
     - **Minimum Deployments:** Set to **iOS 12.0** (or match your main app)
     - **iPhone Orientation:** Portrait only

3. **Build Settings Tab:**
   - Search for "Swift Language Version"
   - Set to **Swift 5**

**✅ Checkpoint:** The ShareExtension target settings should match the main app's deployment target.

---

### Step 4: Set Up App Groups (Critical!)

App Groups allow the Share Extension to communicate with the main app by sharing data through UserDefaults.

#### 4A: Add App Group to Main App (Runner Target)

1. **Select Runner target** (under TARGETS, click Runner)
2. Click on **Signing & Capabilities** tab
3. Click **+ Capability** button (top left corner)
4. Type "App Groups" in search
5. Double-click **App Groups** to add it
6. Under App Groups section, click the **+ button**
7. Enter exactly: `group.com.wishlists.gifts`
8. Click **OK**
9. **CHECK the checkbox** next to `group.com.wishlists.gifts` to enable it

![App Groups Setup](https://developer.apple.com/documentation/xcode/configuring-app-groups)

#### 4B: Add Same App Group to ShareExtension Target

1. **Select ShareExtension target** (under TARGETS)
2. Click on **Signing & Capabilities** tab
3. Click **+ Capability** button
4. Double-click **App Groups**
5. Click the **+ button** under App Groups
6. Enter **the exact same**: `group.com.wishlists.gifts`
7. Click **OK**
8. **CHECK the checkbox** next to `group.com.wishlists.gifts`

**⚠️ Critical:** Both targets MUST have the EXACT same App Group identifier!

**✅ Checkpoint:**
- Both Runner and ShareExtension targets show "App Groups" capability
- Both show `group.com.wishlists.gifts` with a checkmark

---

### Step 5: Configure Share Extension Info.plist

This step defines what types of content can be shared to your app.

1. **Navigate to ShareExtension/Info.plist:**
   - In Xcode navigator, expand `ShareExtension` folder
   - Single-click on `Info.plist`

2. **Open as Source Code:**
   - Right-click on `Info.plist`
   - Select **"Open As" → "Source Code"**

3. **Find the NSExtension section** and look for `NSExtensionActivationRule`

4. **Replace the NSExtensionActivationRule section** with this:

```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsImageWithMaxCount</key>
    <integer>1</integer>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
    <key>NSExtensionActivationSupportsText</key>
    <true/>
</dict>
```

**This allows sharing:**
- ✅ Images (1 at a time)
- ✅ Web URLs (1 at a time)
- ✅ Text content

5. **Save the file** (Cmd+S)

**✅ Checkpoint:** No red errors in Info.plist

---

### Step 6: Update ShareViewController.swift

This is the code that handles the shared content and passes it to the main app.

1. **Open `ShareExtension/ShareViewController.swift`**

2. **Delete ALL existing code**

3. **Replace with this complete implementation:**

```swift
import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    // IMPORTANT: This must match the App Group you created!
    let appGroupId = "group.com.wishlists.gifts"
    let sharedKey = "HeyWishSharedContent"

    override func isContentValid() -> Bool {
        // Always return true to allow posting
        return true
    }

    override func didSelectPost() {
        // Main entry point when user taps "Post"
        if let content = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = content.attachments {
                handleAttachments(attachments)
            } else {
                completeRequest()
            }
        } else {
            completeRequest()
        }
    }

    private func handleAttachments(_ attachments: [NSItemProvider]) {
        // Priority order: URL > Image > Text

        // 1. Check for URLs first (most common for wish items)
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                    if let url = item as? URL {
                        self?.saveSharedData(url: url.absoluteString)
                    } else if let data = item as? Data, let urlString = String(data: data, encoding: .utf8) {
                        self?.saveSharedData(url: urlString)
                    }
                    self?.completeRequest()
                }
                return
            }
        }

        // 2. Check for Images
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                    var imagePath: String?

                    if let url = item as? URL {
                        // Image file URL
                        imagePath = url.path
                    } else if let image = item as? UIImage {
                        // UIImage object - save to temp directory
                        imagePath = self?.saveImageToTemp(image)
                    } else if let data = item as? Data, let image = UIImage(data: data) {
                        // Image data - convert and save
                        imagePath = self?.saveImageToTemp(image)
                    }

                    if let path = imagePath {
                        self?.saveSharedData(imagePath: path)
                    }
                    self?.completeRequest()
                }
                return
            }
        }

        // 3. Fallback to Text
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] (item, error) in
                    if let text = item as? String {
                        // Check if text is a URL
                        if let url = URL(string: text), url.scheme != nil {
                            self?.saveSharedData(url: text)
                        } else {
                            self?.saveSharedData(text: text)
                        }
                    }
                    self?.completeRequest()
                }
                return
            }
        }

        // Nothing matched
        completeRequest()
    }

    private func saveImageToTemp(_ image: UIImage) -> String? {
        let fileName = "heywish_shared_\(Date().timeIntervalSince1970).jpg"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("❌ Error saving shared image: \(error)")
            return nil
        }
    }

    private func saveSharedData(url: String? = nil, imagePath: String? = nil, text: String? = nil) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }

        var sharedData: [String: Any] = [:]
        sharedData["timestamp"] = Date().timeIntervalSince1970

        if let url = url {
            sharedData["type"] = "url"
            sharedData["value"] = url
            print("✅ Saving shared URL: \(url)")
        } else if let imagePath = imagePath {
            sharedData["type"] = "image"
            sharedData["value"] = imagePath
            print("✅ Saving shared image: \(imagePath)")
        } else if let text = text {
            sharedData["type"] = "text"
            sharedData["value"] = text
            print("✅ Saving shared text: \(text)")
        }

        userDefaults.set(sharedData, forKey: sharedKey)
        userDefaults.synchronize()

        print("✅ Shared data saved successfully")
    }

    private func completeRequest() {
        // Close the share extension
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }

        // Open the main app with custom URL scheme
        self.openMainApp()
    }

    private func openMainApp() {
        guard let url = URL(string: "heywish://share") else {
            return
        }

        // Use selector to open URL (works in extension context)
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")

        while let currentResponder = responder {
            if currentResponder.responds(to: selectorOpenURL) {
                currentResponder.perform(selectorOpenURL, with: url)
                break
            }
            responder = currentResponder.next
        }
    }

    override func configurationItems() -> [Any]! {
        // No configuration items needed
        return []
    }
}
```

4. **Save the file** (Cmd+S)

**✅ Checkpoint:** No red compile errors in the file

---

### Step 7: Verify URL Scheme (Already Configured)

Your `Info.plist` already has the `heywish://` URL scheme configured, so this step is done! ✅

---

### Step 8: Build and Test

#### 8A: Clean and Build

1. **Select Runner scheme** (top bar next to device selector)
2. Select a device or simulator
3. **Clean Build Folder:**
   - Menu: `Product` → `Clean Build Folder` (or Shift+Cmd+K)
4. **Build:**
   - Menu: `Product` → `Build` (or Cmd+B)
5. Wait for build to complete
6. **Fix any errors** (there shouldn't be any!)

#### 8B: Run the App

1. Click **Run** (Cmd+R)
2. App should install and launch on your device/simulator
3. Close the app after it launches successfully

#### 8C: Test the Share Extension

**Test 1: Share a URL from Safari**

1. Open **Safari** on your iOS device/simulator
2. Go to any product page (e.g., `amazon.com/dp/B08N5WRWNW`)
3. Tap the **Share button** (square with arrow pointing up)
4. Scroll through the bottom row of app icons
5. Look for **"HeyWish"** icon
   - If you don't see it immediately, scroll right or tap "More"
6. Tap **HeyWish**
7. The share sheet should appear
8. Tap **"Post"**
9. **HeyWish app should open!**

**Test 2: Share an Image from Photos**

1. Open **Photos** app
2. Select any photo
3. Tap **Share button**
4. Tap **HeyWish**
5. Tap **"Post"**
6. HeyWish should open

**Test 3: Share Text from Notes**

1. Open **Notes** app
2. Type some text
3. Select the text
4. Tap **Share**
5. Tap **HeyWish**
6. Tap **"Post"**
7. HeyWish should open

---

## 🐛 Troubleshooting Guide

### Problem: "HeyWish" doesn't appear in Share Sheet

**Solutions to try:**

1. **Complete App Deletion:**
   ```
   - Delete app from device/simulator completely
   - In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
   - Rebuild and reinstall
   ```

2. **Restart Device:**
   ```
   - Sometimes iOS caches Share Extensions
   - Restart the simulator or physical device
   - Reinstall the app
   ```

3. **Check Target Settings:**
   ```
   - Verify ShareExtension target is being built
   - In scheme settings, ensure ShareExtension is checked
   ```

---

### Problem: App Groups not working / data not transferring

**Solutions:**

1. **Verify exact App Group ID:**
   ```
   - Both targets must use: group.com.wishlists.gifts
   - Check for typos
   - Checkbox must be CHECKED for both
   ```

2. **Re-add App Groups:**
   ```
   - Remove App Groups capability from both targets
   - Clean build
   - Re-add App Groups to both targets
   - Use same group ID
   ```

---

### Problem: Build errors in ShareViewController.swift

**Common fixes:**

1. **"Cannot find type 'UTType' in scope"**
   ```swift
   // Make sure you have this import at the top:
   import UniformTypeIdentifiers
   ```

2. **"Use of unresolved identifier"**
   ```
   - Make sure you copied the COMPLETE code
   - Check for missing imports
   ```

---

### Problem: Share Extension opens but doesn't pass data to main app

**Solutions:**

1. **Check App Group ID in code:**
   ```swift
   // In ShareViewController.swift line 7:
   let appGroupId = "group.com.wishlists.gifts"

   // Must match EXACTLY with Capabilities setting
   ```

2. **Check URL scheme:**
   ```
   - Verify Info.plist has heywish:// URL scheme
   - Already configured in your project ✅
   ```

---

### Problem: "This app is not allowed to query for scheme heywish"

**Solution:**
```
Add to Runner's Info.plist:
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>heywish</string>
</array>
```

---

## ✅ Final Verification Checklist

Go through this checklist to ensure everything is set up correctly:

- [ ] ShareExtension target created in Xcode
- [ ] Target uses Swift language
- [ ] Bundle ID is `com.wishlists.gifts.ShareExtension`
- [ ] Deployment target is iOS 12.0 or matches main app
- [ ] App Groups capability added to **Runner** target
- [ ] App Groups capability added to **ShareExtension** target
- [ ] Both targets use `group.com.wishlists.gifts`
- [ ] Both checkboxes are CHECKED
- [ ] Info.plist activation rules configured
- [ ] ShareViewController.swift code updated completely
- [ ] appGroupId in code matches capability
- [ ] Project builds without errors (Cmd+B)
- [ ] App installs and runs
- [ ] HeyWish appears in Safari share sheet
- [ ] HeyWish appears in Photos share sheet
- [ ] Tapping "Post" opens HeyWish app
- [ ] Tested on both simulator and physical device

---

## 📱 Complete Testing Matrix

Test all these scenarios to ensure full functionality:

| Source App | Share Type | Steps | Expected Result |
|------------|-----------|-------|-----------------|
| Safari | Product URL | Browse → Share → HeyWish → Post | App opens, URL detected |
| Safari | Regular URL | Any webpage → Share → HeyWish → Post | App opens, URL passed |
| Photos | Single Image | Photo → Share → HeyWish → Post | App opens, image path passed |
| Notes | Text | Select text → Share → HeyWish → Post | App opens, text passed |
| Messages | Link | Long press link → Share → HeyWish → Post | App opens, link passed |

---

## 🎉 Success Criteria

You'll know it's working when:

1. ✅ "HeyWish" shows up in any app's Share Sheet
2. ✅ Tapping it opens a small share dialog
3. ✅ Tapping "Post" dismisses the dialog
4. ✅ HeyWish main app opens automatically
5. ✅ Wishlist selector appears
6. ✅ Add Wish screen shows with content pre-filled

---

## 🚀 Next Steps

Once Share Extension is working:

1. **Implement Mobile Integration:**
   - Connect ShareHandlerService to main app
   - Listen for shared content on app launch
   - Show wishlist selector
   - Navigate to Add Wish screen

2. **Add URL Scraping:**
   - Call backend API when URL is shared
   - Auto-fill title, price, image from scraped data
   - Show loading indicator during scraping

3. **Polish UX:**
   - Add animations
   - Handle errors gracefully
   - Show success messages

---

## 📚 Additional Resources

- [Apple Share Extension Docs](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/building_share_sheet_extensions)
- [App Groups Setup](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [receive_sharing_intent Package](https://pub.dev/packages/receive_sharing_intent)

---

**Estimated Setup Time:** 15-20 minutes
**Difficulty Level:** Intermediate

**Questions or issues?** Double-check the troubleshooting section or provide the specific error message for help!
