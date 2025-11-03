# Implementation Notes: Line Numbers and RTF Rendering

## Overview
This document provides technical notes about the implementation of line numbers and RTF rendering features in QLStephenSwift.

## Architecture

### Module Structure
```
QLStephenSwift/
├── QLStephenSwift/                    # Main app target
│   ├── TextFormattingSettings.swift   # Settings model (shared)
│   ├── ContentView.swift              # UI with new controls
│   └── QLStephenSwiftApp.swift        # App entry point
├── QLStephenSwiftPreview/             # QuickLook extension target
│   ├── TextFormattingSettings.swift   # Settings model (shared copy)
│   ├── AttributedTextRenderer.swift   # Text rendering engine
│   ├── PreviewProvider.swift          # QuickLook provider (updated)
│   └── FileAnalyzer.swift             # Existing encoding detection
└── QLStephenSwiftTests/               # Test target
    └── TextFormattingTests.swift      # New unit tests
```

### Data Flow

1. **Settings Configuration (Main App)**
   ```
   User toggles in ContentView
   → TextFormattingSettings.save()
   → UserDefaults (App Group)
   ```

2. **QuickLook Preview (Extension)**
   ```
   User presses Space in Finder
   → providePreview() called
   → TextFormattingSettings.load()
   → Choose rendering path:
      ├─ RTF disabled → providePlainTextPreview()
      └─ RTF enabled  → provideRTFPreview()
           └─ AttributedTextRenderer.render()
   ```

## Key Design Decisions

### 1. Dual Copy of TextFormattingSettings
**Problem**: Swift doesn't support shared code between app and extension targets easily.

**Solution**: Two identical copies of TextFormattingSettings.swift
- One in main app target
- One in extension target
- Both read/write to same App Group UserDefaults

**Pros**:
- Simple, no build complexity
- Each target can build independently

**Cons**:
- Must keep both files in sync
- Code duplication

**Alternative Considered**: Shared framework - rejected due to complexity for small project

### 2. Backward Compatibility Strategy
**Approach**: Feature flags default to OFF

```swift
if settings.rtfRenderingEnabled {
    return try provideRTFPreview(...)
} else {
    return try providePlainTextPreview(...)  // Original code path
}
```

**Benefits**:
- Existing users see no change
- Original code path preserved completely
- Easy to verify no regression

### 3. Line Number Formatting
**Specification**: Minimum 4 digits, zero-padded

**Implementation**:
```swift
let digitCount = max(4, String(lineCount).count)
let lineNumberString = String(format: "%0*d", digitCount, lineNumber)
```

**Examples**:
- 1 line → "0001"
- 9999 lines → "9999"
- 10000 lines → "10000" (auto-expand to 5 digits)

### 4. Separator Resolution
**User Input**: String like ":", "|", "space", "tab"

**Implementation**: Normalize common variations
```swift
switch separator.lowercased() {
case "space", " ": return " "
case "tab", "\\t", "\t": return "\t"
case ":", "colon": return ":"
case "|", "pipe": return "|"
default: return separator  // Pass through
}
```

### 5. Tab Width Calculation

**Two Modes**:

1. **Character-based**: Tab = N characters wide
   ```swift
   let characterWidth = font.advancement(forGlyph: font.glyph(withName: "m")).width
   tabWidth = characterWidth * settings.tabWidth.value
   ```

2. **Points-based**: Tab = N points wide
   ```swift
   tabWidth = settings.tabWidth.value
   ```

**Applied via NSParagraphStyle**:
```swift
paragraphStyle.defaultTabInterval = tabWidth
```

### 6. Font Attribute Separation
**Requirement**: Different fonts for line numbers vs content

**Implementation**: Separate attribute dictionaries
```swift
// Line number attributes
let lineNumberAttrs: [NSAttributedString.Key: Any] = [
    .font: lineNumberFont,
    .foregroundColor: settings.lineNumberFont.textColor,
    .backgroundColor: settings.lineNumberFont.backgroundColor
]

// Content attributes
let contentAttrs: [NSAttributedString.Key: Any] = [
    .font: contentFont,
    .foregroundColor: settings.contentFont.textColor,
    .paragraphStyle: paragraphStyle
]
```

## Edge Cases Handled

### 1. Empty Files
**Issue**: Empty file has 1 line (not 0)
```swift
let lines = "".components(separatedBy: .newlines)  // [""]
// lines.count == 1
```
**Result**: Shows "0001 " (line number with no content)

### 2. Trailing Newline
**Issue**: Text ending with `\n` creates empty last line
```swift
"a\nb\n".components(separatedBy: .newlines)  // ["a", "b", ""]
```
**Solution**: Check if original text ends with newline
```swift
if index < lines.count - 1 || text.hasSuffix("\n") {
    result.append(NSAttributedString(string: "\n"))
}
```

### 3. Large Files
**Constraint**: maxFileSize truncation still applies
**Behavior**: 
- File truncated to maxFileSize bytes
- Then line numbers added to truncated content
- Last line may be incomplete

### 4. Encoding Detection
**Integration**: Works with existing FileAnalyzer
```swift
let analysisResult = try FileAnalyzer.analyze(fileURL: fileURL)
let encoding = analysisResult.encoding
```
**RTF Conversion**:
```swift
guard let text = String(data: data, encoding: encoding) else { ... }
```

## Performance Considerations

### Time Complexity
- Line number calculation: O(n) where n = number of lines
- AttributedString generation: O(n × m) where m = average line length
- RTF data conversion: O(result size)

### Memory Usage
- Plain text mode: ~fileSize bytes
- RTF mode: ~fileSize + overhead for attributes
- Large files: Still constrained by maxFileSize

### Optimization Opportunities (Future)
1. Lazy line number generation
2. Streaming RTF generation for very large files
3. Caching of attributed strings

## Testing Strategy

### Unit Tests (Automated)
✅ Line number formatting logic
✅ Digit count calculation
✅ Separator resolution
✅ AttributedString generation
✅ Settings persistence

### Integration Tests (Manual - Requires macOS)
- QuickLook preview with various file types
- UI settings persistence
- Copy/paste functionality
- Encoding compatibility
- Performance with large files

### Regression Tests
- Features OFF → original behavior
- Settings migration from legacy version

## Known Issues and Limitations

### 1. Font Color UI
**Issue**: Color picker requires NSColorPanel integration
**Workaround**: Use defaults commands for color customization
**Future**: Add color picker to settings UI

### 2. Line Selection
**Limitation**: Click-to-select entire line not implemented
**Reason**: Requires custom text view or additional gesture handling
**Current**: Standard text selection works (user can select across line numbers)

### 3. Performance on Extremely Large Files
**Impact**: RTF generation for 100,000+ line files may take 1-2 seconds
**Mitigation**: maxFileSize truncation limits actual content size
**Acceptable**: QuickLook typically used for quick previews, not full file viewing

### 4. Right-to-Left Languages
**Status**: Not explicitly tested
**Expected**: Should work (NSAttributedString supports RTL)
**TODO**: Add RTL language test cases

## Security Considerations

### 1. UserDefaults Access
**Scope**: App Group UserDefaults (`group.com.mycometg3.qlstephenswift`)
**Isolation**: Shared only between main app and extension
**Safety**: No user input directly stored without validation

### 2. Font Name Validation
**Current**: Font name passed to NSFont initializer
**Behavior**: Invalid names fall back to system font
```swift
NSFont(name: fontName, size: size) ?? NSFont.monospacedSystemFont(...)
```

### 3. Input Validation
**Line Separator**: Limited to 4 predefined values + pass-through
**Tab Width**: Numeric value, no security concern
**Font Size**: Numeric value, reasonable ranges enforced by system

## Maintenance Notes

### Keeping TextFormattingSettings in Sync
When modifying TextFormattingSettings.swift:
1. Edit version in QLStephenSwiftPreview/
2. Copy to QLStephenSwift/
3. Verify both copies identical: `diff -u path1 path2`

### Adding New Settings
1. Add property to TextFormattingSettings struct
2. Add UserDefaults key constant
3. Update load() method
4. Update save() method
5. Update default values
6. Add UI control in ContentView
7. Add unit tests

### Debugging Tips
```bash
# View current settings
defaults read group.com.mycometg3.qlstephenswift

# Clear all settings
defaults delete group.com.mycometg3.qlstephenswift

# Reset QuickLook cache
qlmanage -r && qlmanage -r cache
killall Finder

# Test with specific file
qlmanage -p /path/to/testfile
```

## Future Enhancement Ideas

### Short Term
- [ ] Add font picker UI
- [ ] Add color picker UI
- [ ] Add preview pane in settings showing sample output

### Medium Term
- [ ] Syntax highlighting support
- [ ] Custom theme support
- [ ] Export to RTF file feature
- [ ] Line bookmarking

### Long Term
- [ ] Git diff integration
- [ ] Search within preview
- [ ] Collaborative editing markers
- [ ] Plugin system for custom formatters

## References

### Apple Documentation
- [QuickLook Extension Programming Guide](https://developer.apple.com/documentation/quicklook)
- [NSAttributedString](https://developer.apple.com/documentation/foundation/nsattributedstring)
- [NSParagraphStyle](https://developer.apple.com/documentation/uikit/nsparagraphstyle)

### Related Projects
- Original QLStephen (Objective-C)
- QLColorCode (syntax highlighting QuickLook plugin)

### Swift Conventions
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Swift.org Style Guide](https://google.github.io/swift/)

---

**Last Updated**: 2025-11-03
**Author**: GitHub Copilot (Implementation)
**Maintainer**: MyCometG3
