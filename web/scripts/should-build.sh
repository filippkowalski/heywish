#!/bin/bash

# This script checks if there are changes in the web directory
# Exit 0 = skip build, Exit 1 = proceed with build

# Get the list of changed files between HEAD and the previous commit
CHANGED_FILES=$(git diff --name-only HEAD^ HEAD 2>/dev/null || echo "")

# If no previous commit (initial commit), always build
if [ -z "$CHANGED_FILES" ]; then
  echo "No previous commit found or initial commit - proceeding with build"
  exit 1
fi

# Check if any changes are in the web directory
WEB_CHANGES=$(echo "$CHANGED_FILES" | grep "^web/" || true)

if [ -z "$WEB_CHANGES" ]; then
  echo "✓ No changes detected in web/ directory - skipping build"
  exit 0
else
  echo "✓ Changes detected in web/ directory:"
  echo "$WEB_CHANGES"
  echo "Proceeding with build..."
  exit 1
fi
