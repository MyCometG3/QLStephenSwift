# Line Numbers and RTF Rendering Features

This document describes the line number display and RTF rendering features in QLStephenSwift.

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

### Line Ending Preservation
The original line ending style (LF, CR, or CRLF) is automatically detected and preserved in the output. This ensures that files with different line ending styles maintain their original format when line numbers are added.

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
- **Note**: RTF rendering can be used independently of line numbers

#### Font and Color Settings
Font and color settings can be configured through the application UI when RTF rendering is enabled, or via the `defaults` command for advanced settings.

**UI Configurable Settings (Content Text):**
- Font Family: Picker with monospaced fonts (Menlo, Monaco, SF Mono, Courier New, Courier)
- Font Size: Slider (8-24 pt, default: 11.0)
- Text Color (Light Mode): Color picker (default: black)
- Background Color (Light Mode): Color picker (default: white)
- Text Color (Dark Mode): Color picker (default: light gray #E0E0E0)
- Background Color (Dark Mode): Color picker (default: dark gray #1E1E1E)

**Line Number Attributes (Advanced - defaults command only):**
- Font Name: `lineNumberFontName` (default: "Menlo")
- Font Size: `lineNumberFontSize` (default: 11.0)
- Foreground Color: `lineNumberForegroundColor` (default: "#808080" - gray)
- Background Color: `lineNumberBackgroundColor` (default: "#F5F5F5" - light gray)

**Dark Mode Support:**
Colors automatically adapt based on system appearance. The application stores separate color values for Light and Dark modes, ensuring proper text visibility and contrast in both modes.

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

#### Using the UI (Recommended)

The application UI provides controls for the most commonly used settings:
1. Enable "RTF Rendering" toggle
2. Use the Font Settings section to select font family and size
3. Use the Color Settings sections to customize colors for Light and Dark modes
4. Changes are saved automatically and take effect after restarting QuickLook

#### Using defaults Command (Advanced)

Use the `defaults` command to configure line number fonts and other advanced settings:

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

# Set content colors (Light Mode)
defaults write group.com.mycometg3.qlstephenswift contentForegroundColor "#000000"
defaults write group.com.mycometg3.qlstephenswift contentBackgroundColor "#FFFFFF"

# Set content colors (Dark Mode)
defaults write group.com.mycometg3.qlstephenswift contentForegroundColorDark "#E0E0E0"
defaults write group.com.mycometg3.qlstephenswift contentBackgroundColorDark "#1E1E1E"

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
   - **Font and color customization available through UI**
   - Colors automatically adapt to Light/Dark mode

4. **Line Numbers ON, RTF ON**
   - RTF rendering with line numbers
   - Line numbers use separate font/color attributes (configurable via defaults)
   - Content uses customizable font/color attributes (configurable via UI)
   - Tab width can be customized
   - Colors automatically adapt to Light/Dark mode

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

### Line Ending Handling
- Line endings are automatically detected (LF `\n`, CR `\r`, or CRLF `\r\n`)
- Original line ending style is preserved in formatted output
- Single-line files default to LF
- Trailing newlines are preserved when present in the original file

### Performance
- Text formatting happens during preview generation
- For files > max file size, only the truncated portion is formatted
- Line number calculation is O(n) where n = number of lines
- Line ending detection uses single-pass iteration for efficiency

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
   - Files with different line endings (LF, CRLF, CR)

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

**Line endings changed**:
- The formatter automatically preserves the original line ending style
- LF, CR, and CRLF are all supported and maintained
- If you need a specific line ending, convert the file before previewing
