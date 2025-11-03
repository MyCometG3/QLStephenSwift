# Test Scenarios for Line Numbers and RTF Rendering

## Setup
1. Build and install QLStephenSwift.app
2. Enable the QuickLook extension in System Settings
3. Reset QuickLook cache: `qlmanage -r && qlmanage -r cache`
4. Create test files in a temporary directory

## Test Files

### test_small.txt (3 lines)
```
Line one
Line two
Line three
```

### test_medium.txt (50 lines)
```
[Lines 1-50, numbered content]
```

### test_large.txt (15000 lines)
```
[Lines 1-15000, numbered content]
```

### test_tabs.txt
```
Column1	Column2	Column3
Value1	Value2	Value3
Test	Data	Here
```

### test_no_extension (no file extension)
```
#!/bin/bash
echo "Hello World"
exit 0
```

## Test Scenarios

### Scenario 1: Default Behavior (All Features OFF)
**Purpose**: Verify backward compatibility

**Setup**:
- Line Numbers: OFF
- RTF Rendering: OFF

**Steps**:
1. Preview test_small.txt with spacebar
2. Preview test_no_extension with spacebar
3. Preview test_tabs.txt with spacebar

**Expected**:
- Plain text preview
- No line numbers
- Original encoding preserved
- Original behavior maintained

**Verification**:
- [ ] Plain text displayed correctly
- [ ] No line numbers shown
- [ ] Tabs display as tabs
- [ ] Copy/paste works as before

---

### Scenario 2: Line Numbers Only (Space Separator)
**Purpose**: Test line number display with default separator

**Setup**:
- Line Numbers: ON
- Separator: space
- RTF Rendering: OFF

**Steps**:
1. Open QLStephenSwift.app
2. Toggle "Show Line Numbers" ON
3. Verify Separator is "space"
4. Preview test_small.txt

**Expected**:
```
0001 Line one
0002 Line two
0003 Line three
```

**Verification**:
- [ ] Line numbers shown
- [ ] 4 digits with zero padding
- [ ] Space separator between number and text
- [ ] Plain text format (not RTF)
- [ ] Copy includes line numbers

---

### Scenario 3: Line Numbers with Different Separators
**Purpose**: Test all separator options

**Setup**:
- Line Numbers: ON
- RTF Rendering: OFF

**Test 3a - Colon**:
1. Set Separator to "colon"
2. Preview test_small.txt

Expected: `0001:Line one`

**Test 3b - Pipe**:
1. Set Separator to "pipe"
2. Preview test_small.txt

Expected: `0001|Line one`

**Test 3c - Tab**:
1. Set Separator to "tab"
2. Preview test_small.txt

Expected: `0001	Line one` (tab character)

**Verification**:
- [ ] Colon separator works
- [ ] Pipe separator works
- [ ] Tab separator works
- [ ] Separator saved and persists

---

### Scenario 4: Line Number Digit Scaling
**Purpose**: Verify digit width auto-scaling

**Test 4a - Small file (3 lines)**:
- Preview test_small.txt
- Expected: 4 digits (0001, 0002, 0003)

**Test 4b - Medium file (50 lines)**:
- Preview test_medium.txt
- Expected: 4 digits (0001...0050)

**Test 4c - Large file (15000 lines)**:
- Preview test_large.txt
- Expected: 5 digits (00001...15000)

**Verification**:
- [ ] Small files use 4 digits minimum
- [ ] Files with ≤9999 lines use 4 digits
- [ ] Files with ≥10000 lines scale to 5+ digits
- [ ] Padding is consistent throughout file

---

### Scenario 5: RTF Rendering Only (No Line Numbers)
**Purpose**: Test RTF without line numbers

**Setup**:
- Line Numbers: OFF
- RTF Rendering: ON

**Steps**:
1. Toggle "Enable RTF Output" ON
2. Preview test_small.txt

**Expected**:
- RTF formatted output
- No line numbers
- Monospaced font (Menlo 11pt by default)
- Black text on white background

**Verification**:
- [ ] Text is RTF formatted
- [ ] No line numbers shown
- [ ] Font is monospaced
- [ ] Copy preserves formatting in RTF apps
- [ ] Plain text copy works

---

### Scenario 6: RTF with Line Numbers
**Purpose**: Test combined functionality

**Setup**:
- Line Numbers: ON
- Separator: pipe
- RTF Rendering: ON

**Steps**:
1. Enable both features
2. Preview test_small.txt

**Expected**:
- RTF formatted output
- Line numbers with pipe separator
- Line numbers in gray on light gray background
- Content in black on white background
- Different fonts/colors for line numbers vs content

**Verification**:
- [ ] Both line numbers and RTF work together
- [ ] Line numbers have gray styling
- [ ] Content has black styling
- [ ] Separator is part of line number styling
- [ ] Copy includes line numbers
- [ ] Formatting preserved in RTF apps

---

### Scenario 7: Tab Width Configuration
**Purpose**: Test tab width settings

**Setup**:
- RTF Rendering: ON
- Preview test_tabs.txt

**Test 7a - Character mode (4 characters)**:
```bash
defaults write group.com.mycometg3.qlstephenswift tabWidthMode "characters"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 4.0
qlmanage -r && qlmanage -r cache
```

**Test 7b - Character mode (8 characters)**:
```bash
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 8.0
qlmanage -r && qlmanage -r cache
```

**Test 7c - Points mode (32 points)**:
```bash
defaults write group.com.mycometg3.qlstephenswift tabWidthMode "points"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 32.0
qlmanage -r && qlmanage -r cache
```

**Verification**:
- [ ] Tab width changes with character mode
- [ ] Tab width changes with points mode
- [ ] Settings persist after QuickLook restart
- [ ] Tab alignment is consistent

---

### Scenario 8: Custom Fonts and Colors
**Purpose**: Test advanced RTF customization

**Setup**:
```bash
# Configure custom colors
defaults write group.com.mycometg3.qlstephenswift lineNumberForegroundColor "#0066CC"
defaults write group.com.mycometg3.qlstephenswift lineNumberBackgroundColor "#E6F2FF"
defaults write group.com.mycometg3.qlstephenswift contentForegroundColor "#003300"
defaults write group.com.mycometg3.qlstephenswift contentBackgroundColor "#FFFFCC"

# Configure custom fonts
defaults write group.com.mycometg3.qlstephenswift lineNumberFontName "Monaco"
defaults write group.com.mycometg3.qlstephenswift lineNumberFontSize -float 10.0
defaults write group.com.mycometg3.qlstephenswift contentFontName "SF Mono"
defaults write group.com.mycometg3.qlstephenswift contentFontSize -float 12.0

qlmanage -r && qlmanage -r cache
```

**Steps**:
1. Enable Line Numbers and RTF
2. Preview test_small.txt

**Expected**:
- Line numbers in Monaco 10pt, blue on light blue
- Content in SF Mono 12pt, dark green on light yellow

**Verification**:
- [ ] Custom line number font applied
- [ ] Custom line number colors applied
- [ ] Custom content font applied
- [ ] Custom content colors applied
- [ ] Invalid fonts fall back to system font

---

### Scenario 9: Encoding Support
**Purpose**: Verify features work with different encodings

**Test Files**:
- test_utf8.txt (UTF-8)
- test_utf16.txt (UTF-16)
- test_shiftjis.txt (Shift-JIS)

**Setup**:
- Line Numbers: ON
- RTF Rendering: ON

**Steps**:
1. Preview each file

**Expected**:
- Encoding detected correctly
- Line numbers displayed
- Text decoded properly
- No garbled characters

**Verification**:
- [ ] UTF-8 files work
- [ ] UTF-16 files work
- [ ] Shift-JIS files work
- [ ] BOM detected correctly
- [ ] Non-ASCII characters display correctly

---

### Scenario 10: Settings Persistence
**Purpose**: Test settings save and restore

**Steps**:
1. Enable Line Numbers with colon separator
2. Enable RTF Rendering
3. Quit QLStephenSwift.app
4. Restart QLStephenSwift.app

**Expected**:
- Line Numbers still ON
- Separator still "colon"
- RTF Rendering still ON

**Verification**:
- [ ] Settings persist across app restarts
- [ ] Settings stored in App Group UserDefaults
- [ ] QuickLook extension reads settings correctly
- [ ] No settings lost

---

### Scenario 11: Edge Cases

**Test 11a - Empty file**:
- Create empty file
- Preview with line numbers ON
- Expected: No line numbers (or just "0001" for empty line)

**Test 11b - Single line, no newline**:
- Create file: `Single line`
- Preview with line numbers ON
- Expected: `0001 Single line`

**Test 11c - File with trailing newline**:
- Create file: `Line 1\nLine 2\n`
- Preview with line numbers ON
- Expected: Line numbers for actual lines, not extra empty line

**Test 11d - Very long lines**:
- Create file with 1000+ character line
- Preview with line numbers and RTF
- Expected: Line wraps correctly, line number shown once

**Verification**:
- [ ] Empty files handled
- [ ] Single line handled
- [ ] Trailing newlines handled
- [ ] Long lines handled

---

### Scenario 12: Performance
**Purpose**: Verify acceptable performance

**Test 12a - Large file**:
- Preview test_large.txt (15000 lines)
- Time: Should preview in <2 seconds

**Test 12b - Multiple previews**:
- Preview 5 different files quickly
- Expected: No slowdown or lag

**Test 12c - Memory usage**:
- Monitor memory while previewing
- Expected: Reasonable memory usage

**Verification**:
- [ ] Large files preview quickly
- [ ] No noticeable lag
- [ ] Memory usage reasonable
- [ ] No memory leaks

---

## Regression Tests

### RT1: Original Functionality
**Purpose**: Verify no regression in core features

**With features OFF**:
- [ ] Plain text preview works
- [ ] Encoding detection works
- [ ] Binary files rejected
- [ ] .DS_Store ignored
- [ ] Max file size respected

---

### RT2: Settings Migration
**Purpose**: Verify backward compatibility with old settings

**Steps**:
1. Set old domain settings (if applicable)
2. Launch app
3. Verify migration works

**Verification**:
- [ ] Old settings migrated
- [ ] New settings take precedence
- [ ] No data loss

---

## Test Report Template

### Test Session: [Date]
**Tester**: [Name]
**Build**: [Version/Commit]
**macOS Version**: [Version]

| Scenario | Status | Notes |
|----------|--------|-------|
| S1: Default | ☐ Pass ☐ Fail | |
| S2: Line Numbers | ☐ Pass ☐ Fail | |
| S3: Separators | ☐ Pass ☐ Fail | |
| S4: Digit Scaling | ☐ Pass ☐ Fail | |
| S5: RTF Only | ☐ Pass ☐ Fail | |
| S6: RTF + Line Numbers | ☐ Pass ☐ Fail | |
| S7: Tab Width | ☐ Pass ☐ Fail | |
| S8: Custom Fonts | ☐ Pass ☐ Fail | |
| S9: Encodings | ☐ Pass ☐ Fail | |
| S10: Persistence | ☐ Pass ☐ Fail | |
| S11: Edge Cases | ☐ Pass ☐ Fail | |
| S12: Performance | ☐ Pass ☐ Fail | |
| RT1: Original | ☐ Pass ☐ Fail | |
| RT2: Migration | ☐ Pass ☐ Fail | |

**Overall Result**: ☐ Pass ☐ Fail

**Issues Found**:
1. 
2. 
3. 

**Notes**:
