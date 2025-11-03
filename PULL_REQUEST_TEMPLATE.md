# Pull Request: Line Numbers and RTF Rendering Features

## Overview

This PR implements two major features requested in the issue:

### Feature A: Line Number Display
- Toggle line numbers ON/OFF via UI
- Configurable separator between line number and content
- Zero-padded line numbers (minimum 4 digits)
- Automatic digit width adjustment for large files

### Feature B: RTF Rendering
- Toggle RTF rendering ON/OFF via UI
- Custom font configuration (line numbers and content)
- Custom color configuration (text and background)
- Configurable tab width (characters or points mode)
- Line-by-line text selection support

## Changes Summary

### New Files

1. **TextRenderingSettings.swift** (254 lines)
   - Manages all rendering settings
   - Persists to App Group shared UserDefaults
   - Supports mutable/immutable pattern for UI binding

2. **LineNumberFormatter.swift** (56 lines)
   - Calculates digit width based on line count
   - Formats line numbers with zero-padding
   - Adds line numbers to text content

3. **RTFGenerator.swift** (170 lines)
   - Converts text to NSAttributedString
   - Applies custom fonts and colors
   - Configures tab stops and paragraph styles
   - Generates RTF data from AttributedString

4. **LineNumberFormatterTests.swift** (158 lines)
   - Unit tests for digit width calculation
   - Unit tests for line number formatting
   - Unit tests for line number addition

### Modified Files

1. **PreviewProvider.swift**
   - Integrated TextRenderingSettings loading
   - Added logic to switch between plain text and RTF
   - Applied line numbers in both modes

2. **ContentView.swift**
   - Added line numbers toggle
   - Added separator picker
   - Added RTF rendering toggle
   - Added advanced settings disclosure
   - Updated to ScrollView for longer content

3. **QLStephenSwiftApp.swift**
   - Removed fixed window size constraint

4. **README.md**
   - Added new features to feature list
   - Added comprehensive configuration section
   - Documented all UserDefaults keys
   - Provided command-line examples

## Design Decisions

### 1. Settings Architecture
- **Decision**: Use App Group shared UserDefaults
- **Rationale**: Allows QuickLook extension to access settings from main app
- **Impact**: Settings persist across app launches and are shared between app and extension

### 2. Backward Compatibility
- **Decision**: All new features disabled by default
- **Rationale**: Preserves existing behavior for current users
- **Impact**: No breaking changes, opt-in features only

### 3. Line Number Format
- **Decision**: Minimum 4 digits, zero-padded, auto-expanding
- **Rationale**: Balances readability with file size scalability
- **Impact**: Consistent formatting for files up to 9999 lines, automatic adjustment for larger files

### 4. Plain Text vs RTF
- **Decision**: Support line numbers in both modes
- **Rationale**: Users may want line numbers without RTF overhead
- **Impact**: Two code paths, but more flexible for users

### 5. Font Configuration via UserDefaults
- **Decision**: Advanced settings via command-line only
- **Rationale**: Keeps UI simple while providing power user access
- **Impact**: Less UI clutter, documentation-based configuration

### 6. Tab Width Modes
- **Decision**: Support both character-based and point-based
- **Rationale**: Different users have different preferences
- **Impact**: More flexible, accommodates various use cases

## Testing

### Unit Tests
- ✅ Line number digit width calculation
- ✅ Line number zero-padding
- ✅ Line number addition to text
- ✅ Multi-line text handling
- ✅ Large file handling (10,000+ lines)

### Manual Testing Required
Due to environment limitations, the following require manual testing on macOS:
- [ ] RTF generation with custom fonts
- [ ] RTF generation with custom colors
- [ ] Tab width settings (character mode)
- [ ] Tab width settings (point mode)
- [ ] Line-by-line selection in RTF mode
- [ ] UI controls for enabling/disabling features
- [ ] Settings persistence across app launches
- [ ] Various file encodings with RTF
- [ ] Large file performance (>10,000 lines)

## Configuration Examples

### Enable Line Numbers
```bash
defaults write group.com.mycometg3.qlstephenswift lineNumbersEnabled -bool true
defaults write group.com.mycometg3.qlstephenswift lineSeparator " | "
```

### Enable RTF Rendering
```bash
defaults write group.com.mycometg3.qlstephenswift rtfRenderingEnabled -bool true
```

### Customize Fonts
```bash
# Line numbers
defaults write group.com.mycometg3.qlstephenswift lineNumberFontName "Monaco"
defaults write group.com.mycometg3.qlstephenswift lineNumberFontSize -float 10.0

# Content
defaults write group.com.mycometg3.qlstephenswift contentFontName "Menlo"
defaults write group.com.mycometg3.qlstephenswift contentFontSize -float 12.0
```

### Customize Colors
```bash
# Line numbers
defaults write group.com.mycometg3.qlstephenswift lineNumberTextColor "#666666"
defaults write group.com.mycometg3.qlstephenswift lineNumberBackgroundColor "#EEEEEE"

# Content
defaults write group.com.mycometg3.qlstephenswift contentTextColor "#000000"
defaults write group.com.mycometg3.qlstephenswift contentBackgroundColor "#FFFFFF"
```

### Configure Tab Width
```bash
# Character mode (4 characters)
defaults write group.com.mycometg3.qlstephenswift tabWidthMode "characters"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 4.0

# Point mode (32 points)
defaults write group.com.mycometg3.qlstephenswift tabWidthMode "points"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 32.0
```

## Known Limitations

1. **Font Validation**: Invalid font names silently fall back to system monospace font
2. **Color Validation**: Invalid hex colors silently fall back to black/white
3. **Performance**: RTF generation for very large files (>10,000 lines) may be slower
4. **Testing**: Full integration testing requires macOS environment with Xcode

## Screenshots

*(Screenshots to be added after building and running on macOS)*

## Checklist

- [x] Code follows Swift style guidelines
- [x] New features are backward compatible
- [x] Settings are persisted in UserDefaults
- [x] Unit tests added for testable components
- [x] Documentation updated (README)
- [x] Configuration examples provided
- [ ] Manual testing completed (requires macOS)
- [ ] Performance testing with large files (requires macOS)
- [ ] Screenshots added (requires macOS)

## Review Notes

### Code Quality
- All new code includes documentation comments
- Error handling is consistent with existing patterns
- Settings structure is extensible for future enhancements

### Testing Strategy
- Unit tests cover core formatting logic
- Manual testing checklist provided for macOS environment
- Performance considerations documented

### User Experience
- Features are opt-in and disabled by default
- UI is clean and organized with disclosure groups
- Advanced settings don't clutter the main interface

## Future Enhancements

Potential improvements for future PRs:
1. UI controls for font and color selection (font picker, color picker)
2. Preview pane showing sample text with current settings
3. Export/import settings profiles
4. Per-file-extension settings override
5. Syntax highlighting support
