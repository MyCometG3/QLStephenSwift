# Line Numbers and RTF Rendering Features

This document describes the new line number display and RTF rendering features added to QLStephenSwift.

## Feature A: Line Number Display

### Overview
Display line numbers alongside text content in QuickLook previews. This feature can be toggled on/off via the UI.

### Settings

#### Enable Line Numbers
- **UI Control**: Toggle switch in "Line Numbers" section
- **Default**: Off (disabled)
- When enabled, each line is prefixed with its line number

#### Line Number Format
- **Minimum Digits**: 4 digits (e.g., 0001, 0002, 0003)
- **Auto-scaling**: If file has more than 9999 lines, digit width increases automatically
  - 10,000 lines → 5 digits (00001, 00002, ...)
  - 100,000 lines → 6 digits, etc.
- **Zero Padding**: Line numbers are always zero-padded to the calculated width

#### Separator Options
- **UI Control**: Picker in "Line Numbers" section
- **Default**: Space (" ")
- **Available Options**:
  - `space` - Single space character
  - `colon` - Colon character (:)
  - `pipe` - Pipe character (|)
  - `tab` - Tab character

#### Example Output
```
With separator "space":
0001 First line of text
0002 Second line of text
0003 Third line of text

With separator "colon":
0001:First line of text
0002:Second line of text
0003:Third line of text
```

### Backward Compatibility
When line numbers are disabled, the preview displays exactly as before with no changes to the output.

## Feature B: RTF Rendering

### Overview
Render text previews as Rich Text Format (RTF) with customizable fonts, colors, and tab widths. This allows for styled previews with separate formatting for line numbers and content.

### Settings

#### Enable RTF Output
- **UI Control**: Toggle switch in "RTF Rendering" section
- **Default**: Off (disabled)
- When enabled, text is rendered as RTF with attribute styling

#### Font and Color Settings
Font and color settings are stored in UserDefaults and can be configured via the `defaults` command or by editing the plist directly.

**Line Number Attributes:**
- Font Name: `lineNumberFontName` (default: "Menlo")
- Font Size: `lineNumberFontSize` (default: 11.0)
- Foreground Color: `lineNumberForegroundColor` (default: "#808080" - gray)
- Background Color: `lineNumberBackgroundColor` (default: "#F5F5F5" - light gray)

**Content Attributes:**
- Font Name: `contentFontName` (default: "Menlo")
- Font Size: `contentFontSize` (default: 11.0)
- Foreground Color: `contentForegroundColor` (default: "#000000" - black)
- Background Color: `contentBackgroundColor` (default: "#FFFFFF" - white)

#### Tab Width Configuration
- **Mode**: `tabWidthMode` (default: "characters")
  - `characters`: Tab width specified as number of character widths
  - `points`: Tab width specified in points
- **Value**: `tabWidthValue` (default: 4.0)

#### Color Format
Colors are specified as hex strings with optional alpha:
- 6 digits: `#RRGGBB` (e.g., "#FF0000" for red)
- 8 digits: `#RRGGBBAA` (e.g., "#FF0000FF" for red with full opacity)

### Configuring Advanced Settings

Use the `defaults` command to configure font and color settings:

```bash
# Set line number font
defaults write group.com.mycometg3.qlstephenswift lineNumberFontName "Monaco"
defaults write group.com.mycometg3.qlstephenswift lineNumberFontSize -float 10.0

# Set line number colors
defaults write group.com.mycometg3.qlstephenswift lineNumberForegroundColor "#666666"
defaults write group.com.mycometg3.qlstephenswift lineNumberBackgroundColor "#EEEEEE"

# Set content font
defaults write group.com.mycometg3.qlstephenswift contentFontName "SF Mono"
defaults write group.com.mycometg3.qlstephenswift contentFontSize -float 12.0

# Set content colors
defaults write group.com.mycometg3.qlstephenswift contentForegroundColor "#000000"
defaults write group.com.mycometg3.qlstephenswift contentBackgroundColor "#FFFFFF"

# Set tab width (in character widths)
defaults write group.com.mycometg3.qlstephenswift tabWidthMode "characters"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 4.0

# Or set tab width in points
defaults write group.com.mycometg3.qlstephenswift tabWidthMode "points"
defaults write group.com.mycometg3.qlstephenswift tabWidthValue -float 32.0
```

After changing defaults, restart the QuickLook server:
```bash
qlmanage -r && qlmanage -r cache
```

### Copy/Paste Behavior
When RTF rendering is enabled and you copy text from the preview:
- Line numbers are included in the copied text (if line numbers are enabled)
- Formatting is preserved if pasting into an RTF-aware application
- Plain text paste will include line numbers but without formatting

### Backward Compatibility
When RTF rendering is disabled, the preview uses the original plain text rendering with the detected encoding, exactly as before.

## Feature Interaction

The two features can be used independently or together:

1. **Line Numbers OFF, RTF OFF** (default)
   - Original behavior, plain text with detected encoding

2. **Line Numbers ON, RTF OFF**
   - Plain text with line numbers prefixed to each line
   - Uses UTF-8 encoding

3. **Line Numbers OFF, RTF ON**
   - RTF rendering with styled fonts and colors
   - No line numbers shown

4. **Line Numbers ON, RTF ON**
   - RTF rendering with line numbers
   - Line numbers use separate font/color attributes
   - Content uses separate font/color attributes
   - Tab width can be customized

## Examples

### Example 1: Plain Text with Line Numbers
```
Settings:
- Line Numbers: ON
- Separator: space
- RTF: OFF

Output (plain text):
0001 #!/bin/bash
0002 echo "Hello World"
0003 exit 0
```

### Example 2: RTF with Styled Line Numbers
```
Settings:
- Line Numbers: ON
- Separator: pipe
- RTF: ON
- Line Number Font: Menlo, 11pt, Gray on Light Gray
- Content Font: Menlo, 11pt, Black on White

Output (RTF):
0001|#!/bin/bash
0002|echo "Hello World"
0003|exit 0
(with line numbers in gray on light gray background, content in black on white)
```

### Example 3: RTF without Line Numbers
```
Settings:
- Line Numbers: OFF
- RTF: ON
- Content Font: Monaco, 12pt, Dark Blue on Light Yellow

Output (RTF):
#!/bin/bash
echo "Hello World"
exit 0
(styled with Monaco 12pt in dark blue on light yellow background)
```

## Technical Notes

### Encoding Detection
- Text encoding is detected using the existing FileAnalyzer logic
- Detected encoding is used to decode text before formatting
- RTF output is always UTF-8 encoded

### Performance
- Text formatting happens during preview generation
- For files > max file size, only the truncated portion is formatted
- Line number calculation is O(n) where n = number of lines

### Limitations
- Advanced font settings require `defaults` command (not in UI)
- Font names must be valid system fonts
- Invalid font names fall back to system monospaced font
- RTF rendering increases memory usage slightly compared to plain text

## Testing

To test the features:

1. **Enable line numbers only**:
   - Toggle "Show Line Numbers" ON
   - Select a separator
   - Preview a text file with spacebar
   - Verify line numbers appear

2. **Enable RTF rendering**:
   - Toggle "Enable RTF Output" ON
   - Preview a text file
   - Verify text has styling applied

3. **Test with various file types**:
   - README files
   - Shell scripts
   - Configuration files
   - Files with tabs
   - Files with various encodings (UTF-8, UTF-16, Shift-JIS, etc.)

4. **Test copy/paste**:
   - Select text in preview
   - Copy to clipboard
   - Paste into TextEdit (RTF mode)
   - Verify line numbers and formatting are preserved

## Troubleshooting

**Line numbers not showing**:
- Verify "Show Line Numbers" is toggled ON in settings
- Restart QuickLook: `qlmanage -r && qlmanage -r cache`

**RTF styling not applied**:
- Verify "Enable RTF Output" is toggled ON
- Check that font names are valid system fonts
- Restart QuickLook after changing defaults

**Custom colors not working**:
- Verify hex color format is correct (#RRGGBB or #RRGGBBAA)
- Make sure defaults are written to the App Group domain: `group.com.mycometg3.qlstephenswift`
- Restart QuickLook after changing defaults

**Tab width not correct**:
- Verify `tabWidthMode` is set correctly ("characters" or "points")
- Adjust `tabWidthValue` as needed
- Restart QuickLook after changing defaults
