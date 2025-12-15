#!/bin/bash

# Build script for Claude Usage menubar app

APP_NAME="ClaudeUsage"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME}..."

# Create build directory structure
mkdir -p "${BUILD_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy Info.plist
cp Info.plist "${APP_BUNDLE}/Contents/"

# Compile the Swift app
swiftc ClaudeUsageApp.swift \
    -o "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" \
    -framework Cocoa \
    -framework SwiftUI \
    -parse-as-library

if [ $? -eq 0 ]; then
    echo "Build successful! App bundle created at ${APP_BUNDLE}"
    echo ""
    echo "To run the app:"
    echo "  ./run.sh"
    echo ""
    echo "Or open it directly:"
    echo "  open ${APP_BUNDLE}"
else
    echo "Build failed!"
    exit 1
fi
