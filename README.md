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
- ✅ Comprehensive encoding support:
  - BOM detection (UTF-8, UTF-16, UTF-32 BE/LE)
  - Strict UTF-8 validation (RFC 3629 compliant)
  - CJK encodings (Japanese, Korean, Chinese)
  - Western encodings (Windows-1252, MacRoman)
- ✅ Intelligent encoding detection with priority-based fallback
- ✅ Configurable maximum file size limit
- ✅ **Line number display** (optional, configurable separator)
- ✅ **RTF rendering** with customizable fonts, colors, and tab widths
- ✅ macOS 15+ compatible (no external process dependencies)
- ✅ Excludes binary files and `.DS_Store`

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later (for building)

## Installation

### Pre-built Application

1. Download the latest release from [Releases](https://github.com/MyCometG3/QLStephenSwift/releases)
2. Unzip and copy `QLStephenSwift.app` to `/Applications` folder
3. Launch the application once to register the QuickLook extension

### Building from Source

1. Clone and build:
   ```bash
   git clone https://github.com/MyCometG3/QLStephenSwift.git
   cd QLStephenSwift
   open QLStephenSwift/QLStephenSwift.xcodeproj
   ```
2. Build and run the project (⌘R)

### Activation (Required for both methods)

1. Enable the extension in System Settings:
   - **System Settings → Privacy & Security → Extensions → Quick Look**
   - Enable "QLStephenSwift Extension"

2. Reset QuickLook cache and restart Finder:
   ```bash
   qlmanage -r && qlmanage -r cache
   killall Finder
   ```

## Configuration

### Maximum File Size

Configure the maximum file size for preview (default: 100KB, range: 100KB-10MB):

```bash
defaults write group.com.mycometg3.qlstephenswift maxFileSize 204800  # 200KB
```

Valid range: 102400-10485760 bytes (100KB-10MB)

### Line Numbers and RTF Rendering

New features for enhanced text preview:

- **Line Numbers**: Display line numbers with configurable separator (space, colon, pipe, tab)
- **RTF Rendering**: Rich text output with customizable fonts, colors, and tab widths

These features can be enabled/disabled via the application UI. For detailed configuration options and advanced settings, see [FEATURES.md](FEATURES.md).

### Migration from Original QLStephen

Settings are automatically migrated from the original QLStephen on first launch. For manual migration:

```bash
OLD_SIZE=$(defaults read com.whomwah.quicklookstephen maxFileSize 2>/dev/null)
[ -n "$OLD_SIZE" ] && defaults write com.mycometg3.qlstephenswift maxFileSize -int $OLD_SIZE
```

## Usage

Simply select any text file without an extension in Finder and press the Space bar to preview it with QuickLook.

## Supported Content Types

- `public.data` - Generic data files
- `public.content` - Content files
- `public.unix-executable` - Unix executable files (displays shell scripts with shebangs)

## Technical Details

### Binary Detection

Adaptive reading strategy based on file size:
- **Files ≤5MB**: Entire file loaded for encoding detection and complete text decoding
- **Files >5MB**: First 8KB sampled to minimize memory usage

Binary classification rules (applied to sampled data):
- **Immediate rejection**: Any null byte (0x00) → classified as binary
- **Statistical analysis**: Control characters (excluding TAB/LF/CR/FF) > 30% → classified as binary

### Encoding Detection

Multi-stage detection with priority-based fallback to minimize false positives:

1. **BOM Detection** (highest priority)
   - UTF-8, UTF-16 BE/LE, UTF-32 BE/LE

2. **Strict UTF-8 Validation** (RFC 3629 compliant)
   - Validates byte sequence structure
   - Rejects overlong encodings and invalid code points

3. **ICU Statistical Detection**
   - Uses Foundation's `NSString.stringEncoding(for:)` with UTF-8-only suggestion
   - Provides additional heuristic-based detection as safety net

4. **Priority-based Fallback** (in order of strictness and regional relevance)
   - Japanese: ISO-2022-JP, EUC-JP, Shift-JIS
   - Korean: EUC-KR
   - Chinese: GB18030, Big5, GB2312
   - Western: Windows-1252, MacRoman
   - UTF-16/32 BE/LE without BOM (rare, last resort)

5. **Lossy UTF-8** (final fallback)
   - Replaces invalid sequences with U+FFFD replacement characters

## Why QLStephenSwift?

The original QLStephen uses legacy QuickLook Generator plugins with Objective-C and external dependencies (`file` command, `libmagic`). These aren't available in modern macOS sandbox environments.

QLStephenSwift modernizes the approach:
- ✅ Pure Swift implementation with modern QuickLook Extension framework
- ✅ No external dependencies (compatible with macOS 15+ sandbox)
- ✅ Enhanced encoding detection (CJK languages, strict UTF-8 validation)
- ✅ App Extension architecture for better security and reliability

## Troubleshooting

### QuickLook not showing previews

1. Verify extension is enabled: **System Settings → Privacy & Security → Extensions → Quick Look**
2. Reset QuickLook: `qlmanage -r && qlmanage -r cache`
3. Restart Finder: `killall Finder`
4. Check which extension handles files: `qlmanage -m | grep public.data`

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
