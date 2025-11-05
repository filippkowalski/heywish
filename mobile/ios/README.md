# iOS Build Setup

## Known Issue: Xcode Project ObjectVersion

**Problem:** Xcode 17+ (version 26.0.1) automatically upgrades the project format to `objectVersion = 70`, but CocoaPods (xcodeproj 1.27.0) doesn't support this version yet.

**Symptoms:**
- `pod install` fails with error: `Unable to find compatibility version string for object version '70'`
- This happens every time you open the project in Xcode

### Solution

**Option 1: Use the fix script (Recommended)**
```bash
cd mobile/ios
./fix_xcodeproj.sh
pod install
```

**Option 2: Manual fix**
```bash
cd mobile/ios
sed -i '' 's/objectVersion = 70;/objectVersion = 63;/g' Runner.xcodeproj/project.pbxproj
pod install
```

### When to Run This Fix

Run the fix script whenever:
- You get a CocoaPods error about objectVersion 70
- After opening the project in Xcode (Xcode auto-upgrades the format)
- Before running `pod install` or `flutter build ios`

### Long-term Solution

This issue will be resolved when CocoaPods updates xcodeproj to support objectVersion 70. You can track progress here:
- https://github.com/CocoaPods/CocoaPods/issues/12671

### Git Workflow

The `project.pbxproj` file will show as modified after Xcode opens it. You can:
1. Run `./fix_xcodeproj.sh` before committing
2. Or commit with objectVersion 63 (preferred)
3. Don't commit with objectVersion 70 (breaks CocoaPods for the team)
