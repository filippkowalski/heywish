Complete release workflow for both iOS and Android platforms using `cd mobile && fastlane release_all`.

This single command will:
1. **Bump version** in pubspec.yaml (minor version by default)
2. **Update CHANGELOG.md** with commits since last release
3. **Build iOS** and upload to App Store Connect
4. **Build Android** AAB and open folder for Google Play upload

Both platforms will use the same version number. The Android release folder will automatically open in Finder for easy copy-paste to Google Play Console.
