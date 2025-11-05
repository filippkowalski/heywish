#!/bin/bash

# Fix Xcode project objectVersion for CocoaPods compatibility
# Xcode 17+ uses objectVersion 70, but CocoaPods doesn't support it yet
# This script downgrades to objectVersion 63 (compatible with CocoaPods)

PROJECT_FILE="Runner.xcodeproj/project.pbxproj"

if [ -f "$PROJECT_FILE" ]; then
    echo "Checking Xcode project objectVersion..."
    CURRENT_VERSION=$(grep "objectVersion" "$PROJECT_FILE" | sed 's/.*= \([0-9]*\);/\1/')

    if [ "$CURRENT_VERSION" = "70" ]; then
        echo "⚠️  Found objectVersion 70 (incompatible with CocoaPods)"
        echo "📝 Downgrading to objectVersion 63..."
        sed -i '' 's/objectVersion = 70;/objectVersion = 63;/g' "$PROJECT_FILE"
        echo "✅ Fixed! You can now run 'pod install'"
    elif [ "$CURRENT_VERSION" = "63" ]; then
        echo "✅ ObjectVersion is already 63 (compatible)"
    else
        echo "ℹ️  ObjectVersion is $CURRENT_VERSION"
    fi
else
    echo "❌ Error: $PROJECT_FILE not found"
    exit 1
fi
