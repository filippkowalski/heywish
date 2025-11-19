Complete release workflow for both iOS and Android platforms.

**Your tasks:**
1. **Bump version** in `mobile/pubspec.yaml` (prefer minor version bump, e.g., 1.9.0 → 1.10.0, also increment build number)
2. **Update CHANGELOG.md** with a well-written summary of commits since the last release (check git history)
3. **Run** `cd mobile && fastlane release_all` to build and upload both platforms

The fastlane command will:
- Build iOS IPA and upload to App Store Connect
- Build Android AAB
- Open the Android release folder in Finder for easy copy-paste to Google Play Console

Both platforms will use the same version number from pubspec.yaml.
