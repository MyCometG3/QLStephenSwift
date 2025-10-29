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
- ✅ Multi-encoding support (UTF-8, Shift-JIS, EUC-JP, ISO-Latin1, UTF-16)
- ✅ Configurable maximum file size limit
- ✅ macOS 15+ compatible (no external process dependencies)
- ✅ Excludes binary files and `.DS_Store`

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later (for building)

## Installation

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

You can configure the maximum file size for preview (default: 100KB):

```bash
defaults write com.mycometg3.qlstephenswift maxFileSize 204800
```

(Value is in bytes. Example above sets 200KB limit)

### Migration from Original QLStephen

If you previously used the original QLStephen and had configured `maxFileSize`, you can manually migrate your settings with the following command:

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

Or simply set the value directly in the new domain:

```bash
defaults write com.mycometg3.qlstephenswift maxFileSize 204800
```

## Usage

Simply select any text file without an extension in Finder and press the Space bar to preview it with QuickLook.

## Supported Content Types

- `public.data` - Generic data files
- `public.content` - Content files
- `public.unix-executable` - Unix executable files (displays shell scripts with shebangs)

## Technical Details

### Text Detection

The extension uses a custom file analyzer that:
1. Reads the first 8KB of the file
2. Checks for null bytes (indicates binary)
3. Analyzes control character ratio (>30% = binary)
4. Validates text encoding

### Encoding Detection

Automatic encoding detection with the following priority:
1. UTF-8 BOM detection
2. UTF-16 BOM detection (Big/Little Endian)
3. Strict UTF-8 validation
4. Japanese encodings (EUC-JP, Shift-JIS)
5. ISO Latin 1 (fallback)

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

## Authors

**QLStephenSwift**
- Takashi Mochizuki

**Original QLStephen**
- Duncan Robertson
- And [many contributors](https://github.com/whomwah/qlstephen#authors)
