# Claude Usage Menubar App

A simple macOS menubar application that displays your Claude API usage limits in real-time.

## Features

- **Menubar Display**: Shows usage percentage with color-coded icon (🟢 green < 50%, 🟡 yellow 50-80%, 🔴 red > 80%)
- **Simple Dropdown**: Clean, minimal menu showing only the selected metric and reset time
- **Relative Time**: Shows "Resets in 4h 23m" instead of absolute timestamps
- **Settings Window**: Configure your session key and choose which metric to display
- **Metric Options**:
  - 5-hour Limit
  - 7-day Limit (All Models)
  - 7-day Limit (Sonnet)
- **Auto-refresh**: Updates every 5 minutes
- **Persistent Settings**: Session key and preferences saved securely

## Quick Start

### 1. Build the app

```bash
chmod +x build.sh run.sh
./build.sh
```

### 2. Launch the app

```bash
open build/ClaudeUsage.app
```

### 3. Configure settings

1. Click the menubar icon
2. Select "Settings..."
3. Enter your Claude session key
4. Choose which metric to display
5. Click "Save"

## Getting Your Session Key

1. Open [claude.ai](https://claude.ai) in your browser
2. Open Developer Tools (Cmd+Option+I or F12)
3. Go to **Application** > **Cookies** > `https://claude.ai`
4. Find and copy the value of the `sessionKey` cookie
5. Paste it into the Settings window

## Usage

**Menubar**: Shows current usage like "🟢 19%" or "🟡 67%"

**Dropdown Menu**:
- First line: "19% 5-hour Limit" (usage and metric name)
- Second line: "Resets in 4h 23m" (relative time until reset)
- Settings, Refresh, and Quit options

**Keyboard Shortcuts**:
- `Cmd+,` - Open Settings
- `Cmd+R` - Refresh data
- `Cmd+Q` - Quit app

## Settings Storage

Settings are stored in macOS UserDefaults:
- Session key: Stored securely in your user preferences
- Selected metric: Persists between app launches
- Falls back to `CLAUDE_SESSION_KEY` environment variable if not set in Settings

## Requirements

- macOS 13.0 or later
- Xcode Command Line Tools (for Swift compiler)

## Download Pre-built App

Download the latest release from the [Releases](../../releases) page:
1. Download `ClaudeUsage.dmg`
2. Open the DMG file
3. Drag `ClaudeUsage.app` to your Applications folder
4. Launch from Applications

## Building from Source

```bash
# Build
./build.sh

# Run
open build/ClaudeUsage.app

# Or use the run script (checks for environment variable fallback)
./run.sh
```

## Creating a DMG for Distribution

```bash
# Build the app first
./build.sh

# Create DMG
./create-dmg.sh
```

The DMG will be created at `build/ClaudeUsage.dmg`.

## Manual Build

```bash
swiftc ClaudeUsageApp.swift \
  -o build/ClaudeUsage.app/Contents/MacOS/ClaudeUsage \
  -framework Cocoa \
  -framework SwiftUI \
  -parse-as-library
```

## Creating a Release

To publish a new release to GitHub:

1. Commit your changes and push to main
2. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. GitHub Actions will automatically:
   - Build the app
   - Create a DMG file
   - Publish a new release with the DMG attached

You can also trigger the release workflow manually from the Actions tab on GitHub.

## Troubleshooting

**App shows ❌ icon**:
- Session key not configured or invalid
- Open Settings and enter a valid session key

**No data shown**:
- Check network connectivity
- Verify session key is current (they expire periodically)
- Check Console.app for error messages

**Settings not saving**:
- Make sure you click the "Save" button
- Check file permissions for ~/Library/Preferences/

## Privacy

- Session key is stored locally in macOS UserDefaults
- No data is sent anywhere except to claude.ai API
- App only requests usage data from your Claude organization
