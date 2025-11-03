# Testing Guide for Line Numbers and RTF Rendering

This document describes how to test the new line number display and RTF rendering features.

## Prerequisites

1. Build and install the application
2. Enable the QuickLook extension in System Settings
3. Reset QuickLook cache: `qlmanage -r && qlmanage -r cache`

## Test Cases

### Test 1: Basic Line Numbers (Plain Text Mode)

**Setup:**
```bash
defaults write group.com.mycometg3.qlstephenswift lineNumbersEnabled -bool true
defaults write group.com.mycometg3.qlstephenswift lineSeparator -string " "
defaults write group.com.mycometg3.qlstephenswift rtfRenderingEnabled -bool false
```

**Test:**
1. Create a test file without extension containing multiple lines
2. View with QuickLook (press Space in Finder)
3. Verify line numbers appear with format: `0001 <content>`

**Expected Result:**
- Line numbers displayed with minimum 4 digits
- Space separator between number and content
- Plain text rendering (no special formatting)

### Test 2: Line Numbers with Different Separators

**Test each separator:**

```bash
# Colon separator
defaults write group.com.mycometg3.qlstephenswift lineSeparator -string ":"

# Pipe separator
defaults write group.com.mycometg3.qlstephenswift lineSeparator -string "|"

# Tab separator
defaults write group.com.mycometg3.qlstephenswift lineSeparator -string $'\t'
```

**Expected Result:**
- Line numbers appear with the specified separator
- Format: `0001:<content>` or `0001|<content>` or `0001[tab]<content>`

### Test 3: Large Files (>9999 lines)

**Setup:**
```bash
# Generate test file with 12345 lines
for i in {1..12345}; do echo "This is line $i with some content"; done > /tmp/large_test_file
```

**Test:**
1. View the file with QuickLook
2. Scroll to different positions in the file

**Expected Result:**
- Line numbers use 5 digits: `00001`, `01000`, `10000`, `12345`
- Digit width adjusts to accommodate line count

### Test 4: RTF Rendering (Basic)

**Setup:**
```bash
defaults write group.com.mycometg3.qlstephenswift lineNumbersEnabled -bool true
defaults write group.com.mycometg3.qlstephenswift rtfRenderingEnabled -bool true
```

**Test:**
1. Create a test file with multiple lines
2. View with QuickLook

**Expected Result:**
- Line numbers displayed with default formatting
- Text is selectable and copyable
- Content appears in monospace font (Menlo)
- Line numbers have gray background

### Test 5: Custom Font Settings

**Setup:**
```bash
defaults write group.com.mycometg3.qlstephenswift contentFontName -string "Monaco"
defaults write group.com.mycometg3.qlstephenswift contentFontSize -float 12.0
defaults write group.com.mycometg3.qlstephenswift lineNumberFontName -string "Courier"
defaults write group.com.mycometg3.qlstephenswift lineNumberFontSize -float 10.0
```

**Test:**
1. View a file with QuickLook
2. Compare font rendering

**Expected Result:**
- Content appears in Monaco 12pt
- Line numbers appear in Courier 10pt
- Different fonts are visually distinguishable

### Test 6: Tab Width Configuration

**Setup:**
```bash
# Test with character-based tab width
defaults write group.com.mycometg3.qlstephenswift tabWidthMode -string "characters"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 8.0
```

**Test:**
1. Create a file with tab characters:
```
Line with	one tab
Line with		two tabs
	Indented line
```
2. View with QuickLook

**Expected Result:**
- Tabs render with specified width (8 characters)
- Alignment is consistent

**Repeat with points-based tab width:**
```bash
defaults write group.com.mycometg3.qlstephenswift tabWidthMode -string "points"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 40.0
```

### Test 7: Feature Toggle Combinations

Test all combinations:

| Line Numbers | RTF Rendering | Expected Behavior |
|--------------|---------------|-------------------|
| OFF          | OFF           | Original behavior (plain text, no line numbers) |
| ON           | OFF           | Plain text with line numbers prepended |
| OFF          | ON            | RTF rendering without line numbers |
| ON           | ON            | RTF rendering with line numbers |

**Setup for each combination:**
```bash
# Combination 1: Both OFF (default behavior)
defaults write group.com.mycometg3.qlstephenswift lineNumbersEnabled -bool false
defaults write group.com.mycometg3.qlstephenswift rtfRenderingEnabled -bool false

# Combination 2: Line numbers ON, RTF OFF
defaults write group.com.mycometg3.qlstephenswift lineNumbersEnabled -bool true
defaults write group.com.mycometg3.qlstephenswift rtfRenderingEnabled -bool false

# Combination 3: Line numbers OFF, RTF ON
defaults write group.com.mycometg3.qlstephenswift lineNumbersEnabled -bool false
defaults write group.com.mycometg3.qlstephenswift rtfRenderingEnabled -bool true

# Combination 4: Both ON
defaults write group.com.mycometg3.qlstephenswift lineNumbersEnabled -bool true
defaults write group.com.mycometg3.qlstephenswift rtfRenderingEnabled -bool true
```

### Test 8: Edge Cases

**Empty File:**
- Create empty file, view with QuickLook
- Expected: Should handle gracefully (shows line 0001 with no content)

**File with Only Newlines:**
```bash
echo -e "\n\n\n" > /tmp/newlines_only
```
- Expected: Shows line numbers for each line (0001, 0002, 0003, 0004)

**Very Long Lines:**
```bash
python3 -c "print('x' * 10000)" > /tmp/long_line
```
- Expected: Handles long lines without crashing, horizontal scrolling if needed

**Mixed Line Endings:**
- Test files with different line endings (LF, CRLF)
- Expected: Line numbers appear correctly regardless of line ending style

### Test 9: Copy/Paste Functionality

**Test:**
1. Enable RTF rendering with line numbers
2. View a file in QuickLook
3. Select text content
4. Copy (⌘C) and paste into TextEdit

**Expected Result:**
- Selected text includes both line numbers and content
- Paste preserves the line numbers
- Text remains readable

### Test 10: Performance Test

**Setup:**
```bash
# Generate large file (100,000 lines)
for i in {1..100000}; do echo "Line $i content"; done > /tmp/huge_file
```

**Test:**
1. View with QuickLook
2. Measure load time and responsiveness

**Expected Result:**
- File loads within reasonable time (file will be truncated to maxFileSize)
- QuickLook remains responsive
- Memory usage is acceptable

### Test 11: UI Settings Persistence

**Test:**
1. Open QLStephenSwift.app
2. Toggle line numbers ON
3. Change separator to ":"
4. Toggle RTF rendering ON
5. Close app
6. Reopen app

**Expected Result:**
- All settings persist and are restored correctly
- QuickLook preview reflects the saved settings immediately

### Test 12: Encoding Compatibility

Test with files in different encodings:
- UTF-8
- UTF-16
- Shift-JIS (Japanese)
- Windows-1252

**Expected Result:**
- Line numbers appear correctly regardless of encoding
- Content displays properly in its original encoding
- No corruption or garbled characters

## Cleanup

Reset to default settings:
```bash
defaults delete group.com.mycometg3.qlstephenswift lineNumbersEnabled
defaults delete group.com.mycometg3.qlstephenswift lineSeparator
defaults delete group.com.mycometg3.qlstephenswift rtfRenderingEnabled
defaults delete group.com.mycometg3.qlstephenswift contentFontName
defaults delete group.com.mycometg3.qlstephenswift contentFontSize
defaults delete group.com.mycometg3.qlstephenswift lineNumberFontName
defaults delete group.com.mycometg3.qlstephenswift lineNumberFontSize
defaults delete group.com.mycometg3.qlstephenswift tabWidthMode
defaults delete group.com.mycometg3.qlstephenswift tabWidthValue

# Reset QuickLook cache
qlmanage -r && qlmanage -r cache
killall Finder
```

## Known Limitations

1. **Font color customization**: Currently requires using archived NSColor data via defaults system
2. **Maximum file size**: Features respect the maxFileSize setting; very large files are truncated
3. **Performance**: RTF rendering with line numbers on very large files may be slower than plain text
4. **Line selection**: Individual line selection (click to select line) is not implemented; standard text selection works normally
