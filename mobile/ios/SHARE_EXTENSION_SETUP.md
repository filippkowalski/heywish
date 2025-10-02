# iOS Share Extension Setup Instructions

The `receive_sharing_intent` package requires a Share Extension target to be created in Xcode. Follow these steps:

## Steps to Create Share Extension

1. **Open the project in Xcode:**
   ```bash
   cd /Users/filip.zapper/Workspace/heywish/mobile/ios
   open Runner.xcworkspace
   ```

2. **Create a new Share Extension target:**
   - In Xcode, go to `File` → `New` → `Target`
   - Select `Share Extension` under `iOS`
   - Click `Next`
   - Product Name: `ShareExtension`
   - Language: `Swift` or `Objective-C`
   - Click `Finish`
   - When prompted "Activate ShareExtension scheme?", click `Cancel`

3. **Configure the Share Extension:**
   - Select the ShareExtension target
   - In `General` tab:
     - Set Bundle Identifier to: `com.wishlists.gifts.ShareExtension`
     - Set Deployment Target to match the main app (iOS 12.0+)

4. **Update Share Extension Info.plist:**
   - Navigate to `ShareExtension/Info.plist`
   - Add these keys under `NSExtension` → `NSExtensionAttributes`:
     ```xml
     <key>NSExtensionActivationRule</key>
     <dict>
         <key>NSExtensionActivationSupportsImageWithMaxCount</key>
         <integer>1</integer>
         <key>NSExtensionActivationSupportsText</key>
         <true/>
         <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
         <integer>1</integer>
     </dict>
     ```

5. **Update ShareExtension code:**
   - Replace the contents of `ShareViewController.swift` with the code from the `receive_sharing_intent` package documentation
   - This code should handle extracting the shared content and passing it to the main app

6. **Set up App Groups:**
   - Select the main `Runner` target
   - Go to `Signing & Capabilities`
   - Click `+ Capability` and add `App Groups`
   - Create a new group: `group.com.wishlists.gifts`
   - Select the `ShareExtension` target and repeat the same process
   - Ensure both targets have the same app group enabled

7. **Build and run:**
   - Select the `Runner` scheme
   - Build the project
   - Test by sharing a URL or image from Safari to your app

## Alternative: Simpler Approach

The current implementation uses the `receive_sharing_intent` package which handles:
- Listening for shared content when app is opened
- Processing URLs and images shared from other apps
- No need for manual Share Extension if you want basic share functionality

The app will automatically appear in the Share sheet once the package is configured and the app is installed.
