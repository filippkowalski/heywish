//
//  ShareViewController.swift
//  Share Extension
//
//  Created by Filip Kowalski on 20/10/25.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // IMPORTANT: This must match the App Group you created!
    let appGroupId = "group.com.wishlists.gifts"
    let sharedKey = "JinnieSharedContent"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Immediately process and dismiss - no UI needed
        processSharedContent()
    }

    private func processSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }

        handleAttachments(attachments)
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
        let fileName = "jinnie_shared_\(Date().timeIntervalSince1970).jpg"
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
        // Open the main app using the URL scheme
        let appURL = URL(string: "jinnie://share")!

        DispatchQueue.main.async { [weak self] in
            // Try to open the app
            self?.openURL(appURL)

            // Complete the extension request
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: { _ in
                print("✅ Share extension completed and app opened")
            })
        }
    }

    @objc func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }

        // Fallback: Use extensionContext to open URL
        extensionContext?.open(url, completionHandler: { success in
            print(success ? "✅ App opened successfully" : "❌ Failed to open app")
        })
    }

}
