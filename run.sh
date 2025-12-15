#!/bin/bash

# Run script for Claude Usage menubar app

APP_NAME="ClaudeUsage"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

# Check if app exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "App not found. Building first..."
    ./build.sh
fi

# Check for session key
if [ -z "$CLAUDE_SESSION_KEY" ]; then
    echo "Error: CLAUDE_SESSION_KEY environment variable not set"
    echo ""
    echo "Please set your Claude session key:"
    echo "  export CLAUDE_SESSION_KEY='your-session-key-here'"
    echo ""
    echo "To find your session key:"
    echo "  1. Open claude.ai in your browser"
    echo "  2. Open Developer Tools (Cmd+Option+I)"
    echo "  3. Go to Application > Cookies > https://claude.ai"
    echo "  4. Copy the value of the 'sessionKey' cookie"
    exit 1
fi

echo "Starting ${APP_NAME}..."
open "${APP_BUNDLE}"
