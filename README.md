# QLStephenSwift

A modern QuickLook extension for macOS that allows you to preview plain text files without file extensions.

## Overview

QLStephenSwift is a complete rewrite of the legacy [QLStephen](https://github.com/whomwah/qlstephen) project using Swift and the latest macOS QuickLook framework. It provides QuickLook previews for text files that don't have file extensions, such as:

- README
- Makefile
- CHANGELOG
- LICENSE
- Shell scripts without extensions
- Configuration files
- And many more...

## Features

- ✅ Pure Swift implementation using modern QuickLook Extension framework
- ✅ Automatic text/binary file detection
- ✅ Multi-encoding support with BOM detection (UTF-8, UTF-16, UTF-32, Shift-JIS, EUC-JP, ISO-Latin1)
- ✅ ICU-based encoding detection using Foundation/NSString APIs
- ✅ Configurable maximum file size limit
- ✅ macOS 15+ compatible (no external process dependencies)
- ✅ Excludes binary files and `.DS_Store`

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later (for building)

## Installation

### Pre-built Application

1. Download the latest release from [Releases](https://github.com/MyCometG3/QLStephenSwift/releases)

2. Unzip and copy `QLStephenSwift.app` to `/Applications` folder

3. Launch the application once to enable the QuickLook extension

4. Enable the extension in System Settings:
   - System Settings > Privacy & Security > Extensions > Quick Look
   - Enable "QLStephenSwift Extension"

5. Reset QuickLook cache:
   ```bash
   qlmanage -r
   qlmanage -r cache
   ```

6. Restart Finder (hold Option key, right-click Finder icon in Dock, select "Relaunch")

### Building from Source

1. Clone this repository:
   ```bash
   git clone https://github.com/MyCometG3/QLStephenSwift.git
   cd QLStephenSwift
   ```

2. Open `QLStephenSwift/QLStephenSwift.xcodeproj` in Xcode

3. Build and run the project (⌘R)

4. The QuickLook extension will be automatically enabled

5. Reset QuickLook cache:
   ```bash
   qlmanage -r
   qlmanage -r cache
   ```

6. Restart Finder (hold Option key, right-click Finder icon in Dock, select "Relaunch")

## Configuration

### Maximum File Size

You can configure the maximum file size for preview (default: 100KB, range: 100KB-10MB):

```bash
defaults write com.mycometg3.qlstephenswift maxFileSize 204800
```

(Value is in bytes. Example above sets 200KB limit. Valid range: 102400-10485760 bytes)

### Settings Storage

QLStephenSwift uses App Groups to share settings between the main app and QuickLook extension in a sandboxed environment. Settings are automatically migrated from legacy domains when you first launch the app.

### Migration from Original QLStephen

When you first launch QLStephenSwift, it automatically migrates your `maxFileSize` setting from the original QLStephen (if it exists). The migration happens once and preserves your existing configuration.

If you prefer to manually set the value:

```bash
defaults write com.mycometg3.qlstephenswift maxFileSize 204800
```

For manual migration from the original QLStephen:

```bash
# Read the old setting
OLD_SIZE=$(defaults read com.whomwah.quicklookstephen maxFileSize 2>/dev/null)

# If old setting exists, copy it to new domain
if [ ! -z "$OLD_SIZE" ]; then
  defaults write com.mycometg3.qlstephenswift maxFileSize -int $OLD_SIZE
  echo "✅ Migrated maxFileSize: $OLD_SIZE"
else
  echo "ℹ️  No old settings found"
fi
```

## Usage

Simply select any text file without an extension in Finder and press the Space bar to preview it with QuickLook.

## Supported Content Types

- `public.data` - Generic data files
- `public.content` - Content files
- `public.unix-executable` - Unix executable files (displays shell scripts with shebangs)

## Technical Details

### Settings Management

QLStephenSwift uses App Groups (`group.com.mycometg3.qlstephenswift`) to share settings between the main application and QuickLook extension. This enables both components to access the same configuration in macOS's sandboxed environment. Settings are automatically migrated from legacy storage locations on first launch.

### Text Detection

The extension uses a custom file analyzer with adaptive reading strategy:
1. For files ≤5MB: reads entire file for accurate encoding detection
2. For files >5MB: reads first 8KB to minimize memory usage
3. Checks for null bytes (indicates binary)
4. Analyzes control character ratio (>30% threshold = binary)
5. Validates text encoding with multiple methods

### Encoding Detection

Automatic encoding detection with the following priority:
1. **BOM Detection**: UTF-8, UTF-16 (BE/LE), UTF-32 (BE/LE)
2. **ICU-based Detection**: Uses Foundation's `NSString.stringEncoding(for:)` with suggested encodings
3. **Fallback Encodings**: UTF-8, Shift-JIS, EUC-JP, ISO-Latin1 (tried in order)
4. **Lossy UTF-8**: Last resort with replacement characters for undetected encodings

The implementation properly handles BOM stripping and prevents double I/O operations for optimal performance.

## Differences from Original QLStephen

- **No external dependencies**: QLStephenSwift doesn't use `libmagic` or the `file` command (not available in macOS 15+ QuickLook Extensions)
- **Swift-based**: Complete rewrite in Swift using modern APIs
- **QuickLook Extension**: Uses the new App Extension architecture instead of legacy QuickLook Plugin

## Why the Rewrite?

The original QLStephen uses the legacy QuickLook Generator plugin format, which:
- Uses Objective-C and older APIs
- Relies on the `file` command for MIME type detection
- May face compatibility issues with newer macOS versions

QLStephenSwift addresses these by:
- Using the modern QuickLook Preview Extension framework
- Implementing file detection in pure Swift
- Being compatible with macOS 15+ sandbox restrictions

## Troubleshooting

### QuickLook not showing previews

1. Make sure the extension is enabled:
   - System Settings > Privacy & Security > Extensions > Quick Look
   - Enable "QLStephenSwift Extension"

2. Reset QuickLook cache:
   ```bash
   qlmanage -r
   qlmanage -r cache
   ```

3. Restart Finder

### Check which extension handles a file type

```bash
qlmanage -m | grep public.data
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original [QLStephen](https://github.com/whomwah/qlstephen) by Duncan Robertson
- Inspired by the need for a modern, Swift-based QuickLook solution
- Implementation assisted by GitHub Copilot with Claude Sonnet 4.5

## Authors

**QLStephenSwift**
- MyCometG3

**Original QLStephen**
- Duncan Robertson
- And [many contributors](https://github.com/whomwah/qlstephen#authors)
