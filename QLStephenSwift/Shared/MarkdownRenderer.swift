//
//  MarkdownRenderer.swift
//  QLStephenSwift
//
//  Created by Takashi Mochizuki on 2026/11/07.
//  Copyright © 2026 MyCometG3. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

/// Handles Markdown rendering to HTML and interactive view toggling for Quick Look previews.
struct MarkdownRenderer {
    
    /// Settings for Markdown preview
    struct Settings {
        let enabled: Bool
        let defaultView: String // "rendered" or "plain"
        let lineNumbersEnabled: Bool
        let lineSeparator: String
        
        init(
            enabled: Bool = AppConstants.Markdown.defaultEnabled,
            defaultView: String = AppConstants.Markdown.defaultViewMode,
            lineNumbersEnabled: Bool = AppConstants.LineNumbers.defaultEnabled,
            lineSeparator: String = AppConstants.LineNumbers.defaultSeparator
        ) {
            self.enabled = enabled
            self.defaultView = defaultView
            self.lineNumbersEnabled = lineNumbersEnabled
            self.lineSeparator = lineSeparator
        }
        
        /// Load settings from UserDefaults
        static func load(from defaults: UserDefaults) -> Settings {
            let enabled = defaults.object(forKey: AppConstants.Markdown.enabledKey) != nil
                ? defaults.bool(forKey: AppConstants.Markdown.enabledKey)
                : AppConstants.Markdown.defaultEnabled
            let defaultView = defaults.string(forKey: AppConstants.Markdown.defaultViewKey)
                ?? AppConstants.Markdown.defaultViewMode
            let lineNumbersEnabled = defaults.bool(forKey: AppConstants.LineNumbers.enabledKey)
            let lineSeparator = defaults.string(forKey: AppConstants.LineNumbers.separatorKey)
                ?? AppConstants.LineNumbers.defaultSeparator
            
            return Settings(
                enabled: enabled,
                defaultView: defaultView,
                lineNumbersEnabled: lineNumbersEnabled,
                lineSeparator: lineSeparator
            )
        }
    }
    
    // MARK: - Markdown Detection
    
    private static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]
    private static let knownMarkdownDocNames: Set<String> = [
        "README", "CHANGELOG", "CONTRIBUTING", "RELEASE_NOTES", "NOTES", "TODO", "INSTALL", "HISTORY", "AUTHORS"
    ]
    private static let excludedExtensionlessNames: Set<String> = [
        "MAKEFILE", "RAKEFILE", "DOCKERFILE", "GEMFILE", "VAGRANTFILE", "PROCFILE", "BREWFILE"
    ]
    
    /// Determines whether the given file and sample content represents Markdown
    /// - Parameters:
    ///   - fileURL: The URL of the file to inspect
    ///   - sampleText: Optional decoded sample text of the file
    /// - Returns: True if file is determined to be Markdown
    static func isMarkdown(fileURL: URL, sampleText: String? = nil) -> Bool {
        let ext = fileURL.pathExtension.lowercased()
        if markdownExtensions.contains(ext) {
            return true
        }
        
        // Check Uniform Type Identifier
        if let values = try? fileURL.resourceValues(forKeys: [.contentTypeKey]),
           let contentType = values.contentType {
            if contentType.conforms(to: UTType(importedAs: "net.daringfireball.markdown")) {
                return true
            }
        }
        
        // For files without extension (e.g. README, CHANGELOG)
        if ext.isEmpty {
            let filename = fileURL.deletingPathExtension().lastPathComponent.uppercased()
            if excludedExtensionlessNames.contains(filename) {
                return false
            }
            
            if let text = sampleText {
                // If it starts with a shebang, it's an executable script
                if text.hasPrefix("#!") {
                    return false
                }
                
                if knownMarkdownDocNames.contains(filename) {
                    return hasMarkdownMarkers(text)
                } else {
                    return hasStrongMarkdownMarkers(text)
                }
            }
        }
        
        return false
    }
    
    /// Checks if text contains common markdown markers
    private static func hasMarkdownMarkers(_ text: String) -> Bool {
        let lines = text.components(separatedBy: "\n").prefix(50)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if matchHeading(trimmed) != nil ||
               trimmed.hasPrefix("```") ||
               trimmed.hasPrefix("~~~") ||
               trimmed.hasPrefix("> ") ||
               matchUnorderedListItem(trimmed) != nil ||
               matchOrderedListItem(trimmed) != nil ||
               isHorizontalRule(trimmed) {
                return true
            }
        }
        // Also check inline patterns
        if text.range(of: #"\[.+?\]\(.+?\)"#, options: .regularExpression) != nil ||
           text.range(of: #"\*\*.+?\*\*"#, options: .regularExpression) != nil {
            return true
        }
        return false
    }
    
    /// Checks if text has strong markdown indicators for arbitrary extensionless files
    private static func hasStrongMarkdownMarkers(_ text: String) -> Bool {
        var markerCount = 0
        let lines = text.components(separatedBy: "\n").prefix(60)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if matchHeading(trimmed) != nil {
                markerCount += 2
            } else if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                markerCount += 2
            } else if matchUnorderedListItem(trimmed) != nil || matchOrderedListItem(trimmed) != nil {
                markerCount += 1
            }
            if markerCount >= 3 {
                return true
            }
        }
        return false
    }
    
    // MARK: - HTML Escaping
    
    /// Escapes HTML special characters in string
    static func escapeHTML(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        return result
    }
    
    // MARK: - Markdown to HTML Parsing
    
    /// Parses inline Markdown formatting (bold, italic, code, links, images, strikethrough, autolinks)
    static func renderInline(_ text: String) -> String {
        var result = escapeHTML(text)
        
        // Inline code: `code`
        result = result.replacingOccurrences(
            of: "`([^`]+)`",
            with: "<code>$1</code>",
            options: .regularExpression
        )
        
        // Images: ![alt](url)
        result = result.replacingOccurrences(
            of: #"!\[(.*?)\]\((.*?)\)"#,
            with: #"<img src="$2" alt="$1" />"#,
            options: .regularExpression
        )
        
        // Links: [text](url)
        result = result.replacingOccurrences(
            of: #"\[(.*?)\]\((.*?)\)"#,
            with: #"<a href="$2" target="_blank" rel="noopener">$1</a>"#,
            options: .regularExpression
        )
        
        // Bold + Italic: ***text*** or ___text___
        result = result.replacingOccurrences(
            of: #"\*\*\*(.*?)\*\*\*"#,
            with: #"<strong><em>$1</em></strong>"#,
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"___(.*?)___"#,
            with: #"<strong><em>$1</em></strong>"#,
            options: .regularExpression
        )
        
        // Bold: **text** or __text__
        result = result.replacingOccurrences(
            of: #"\*\*(.*?)\*\*"#,
            with: #"<strong>$1</strong>"#,
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"__(.*?)__"#,
            with: #"<strong>$1</strong>"#,
            options: .regularExpression
        )
        
        // Italic: *text* or _text_
        result = result.replacingOccurrences(
            of: #"(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)"#,
            with: #"<em>$1</em>"#,
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"(?<!_)_(?!_)(.*?)(?<!_)_(?!_)"#,
            with: #"<em>$1</em>"#,
            options: .regularExpression
        )
        
        // Strikethrough: ~~text~~
        result = result.replacingOccurrences(
            of: #"~~(.*?)~~"#,
            with: #"<del>$1</del>"#,
            options: .regularExpression
        )
        
        // Autolinks: <https://...>
        result = result.replacingOccurrences(
            of: #"&lt;(https?://[^&]+)&gt;"#,
            with: #"<a href="$1" target="_blank" rel="noopener">$1</a>"#,
            options: .regularExpression
        )
        
        return result
    }
    
    /// Converts Markdown text into HTML body content
    static func markdownToHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var htmlLines: [String] = []
        var index = 0
        let count = lines.count
        
        var inList = false
        var listType = "" // "ul" or "ol"
        
        func closeListIfNeeded() {
            if inList {
                htmlLines.append("</\(listType)>")
                inList = false
                listType = ""
            }
        }
        
        while index < count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Fenced code block (``` or ~~~)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                closeListIfNeeded()
                let fence = String(trimmed.prefix(3))
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                index += 1
                var codeLines: [String] = []
                while index < count {
                    let codeLine = lines[index]
                    let codeTrimmed = codeLine.trimmingCharacters(in: .whitespaces)
                    if codeTrimmed.hasPrefix(fence) {
                        break
                    }
                    codeLines.append(escapeHTML(codeLine))
                    index += 1
                }
                let langClass = lang.isEmpty ? "" : " class=\"language-\(escapeHTML(lang))\""
                htmlLines.append("<pre><code\(langClass)>" + codeLines.joined(separator: "\n") + "</code></pre>")
                index += 1
                continue
            }
            
            // Blank line
            if trimmed.isEmpty {
                closeListIfNeeded()
                index += 1
                continue
            }
            
            // Heading: # Heading
            if let headingMatch = matchHeading(trimmed) {
                closeListIfNeeded()
                let level = headingMatch.level
                let text = renderInline(headingMatch.text)
                htmlLines.append("<h\(level)>\(text)</h\(level)>")
                index += 1
                continue
            }
            
            // Horizontal rule: ---, ***, ___
            if isHorizontalRule(trimmed) {
                closeListIfNeeded()
                htmlLines.append("<hr />")
                index += 1
                continue
            }
            
            // Blockquote: > text
            if trimmed.hasPrefix(">") {
                closeListIfNeeded()
                var quoteLines: [String] = []
                while index < count {
                    let qLine = lines[index].trimmingCharacters(in: .whitespaces)
                    if qLine.hasPrefix(">") {
                        let text = String(qLine.dropFirst()).trimmingCharacters(in: .whitespaces)
                        quoteLines.append(text)
                        index += 1
                    } else if !qLine.isEmpty && !quoteLines.isEmpty {
                        // Continuation line
                        quoteLines.append(qLine)
                        index += 1
                    } else {
                        break
                    }
                }
                let quoteContent = renderInline(quoteLines.joined(separator: " "))
                htmlLines.append("<blockquote><p>\(quoteContent)</p></blockquote>")
                continue
            }
            
            // Table: | col | col |
            if trimmed.hasPrefix("|") && trimmed.contains("|") {
                closeListIfNeeded()
                if let (tableHTML, rowsConsumed) = parseTable(lines: Array(lines[index...])) {
                    htmlLines.append(tableHTML)
                    index += rowsConsumed
                    continue
                }
            }
            
            // Unordered list item: - , * , +
            if let itemText = matchUnorderedListItem(trimmed) {
                if !inList || listType != "ul" {
                    closeListIfNeeded()
                    htmlLines.append("<ul>")
                    inList = true
                    listType = "ul"
                }
                htmlLines.append(renderListItem(itemText))
                index += 1
                continue
            }
            
            // Ordered list item: 1. , 2.
            if let itemText = matchOrderedListItem(trimmed) {
                if !inList || listType != "ol" {
                    closeListIfNeeded()
                    htmlLines.append("<ol>")
                    inList = true
                    listType = "ol"
                }
                htmlLines.append(renderListItem(itemText))
                index += 1
                continue
            }
            
            // Regular paragraph
            closeListIfNeeded()
            var paraLines: [String] = []
            while index < count {
                let pLine = lines[index]
                let pTrimmed = pLine.trimmingCharacters(in: .whitespaces)
                if pTrimmed.isEmpty || matchHeading(pTrimmed) != nil || pTrimmed.hasPrefix("```") ||
                   pTrimmed.hasPrefix("~~~") || pTrimmed.hasPrefix(">") || isHorizontalRule(pTrimmed) ||
                   matchUnorderedListItem(pTrimmed) != nil || matchOrderedListItem(pTrimmed) != nil ||
                   (pTrimmed.hasPrefix("|") && pTrimmed.contains("|")) {
                    break
                }
                paraLines.append(pLine)
                index += 1
            }
            if !paraLines.isEmpty {
                let joinedText = renderInline(paraLines.joined(separator: "\n"))
                htmlLines.append("<p>\(joinedText)</p>")
            }
        }
        
        closeListIfNeeded()
        return htmlLines.joined(separator: "\n")
    }
    
    private static func matchHeading(_ text: String) -> (level: Int, text: String)? {
        var count = 0
        for char in text {
            if char == "#" {
                count += 1
            } else {
                break
            }
        }
        if count >= 1 && count <= 6 {
            let remainder = text.dropFirst(count)
            if remainder.hasPrefix(" ") || remainder.hasPrefix("\t") {
                var headingText = remainder.trimmingCharacters(in: .whitespaces)
                // Trim trailing optional closing hashes (e.g. "# Heading #" -> "Heading")
                while headingText.hasSuffix("#") {
                    headingText = String(headingText.dropLast()).trimmingCharacters(in: .whitespaces)
                }
                return (count, headingText)
            }
        }
        return nil
    }
    
    private static func isHorizontalRule(_ text: String) -> Bool {
        let pattern = #"^(\*{3,}|-{3,}|_{3,})$"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
    
    private static func matchUnorderedListItem(_ text: String) -> String? {
        if text.hasPrefix("- ") || text.hasPrefix("* ") || text.hasPrefix("+ ") {
            return String(text.dropFirst(2))
        }
        return nil
    }
    
    private static func matchOrderedListItem(_ text: String) -> String? {
        if let match = text.range(of: #"^\d+\.\s+(.*)$"#, options: .regularExpression) {
            let item = text[match]
            if let dotIndex = item.firstIndex(of: ".") {
                let afterDot = item[item.index(after: dotIndex)...].trimmingCharacters(in: .whitespaces)
                return String(afterDot)
            }
        }
        return nil
    }
    
    private static func renderListItem(_ text: String) -> String {
        // Check for task checkbox: [ ] or [x]
        if text.hasPrefix("[ ] ") {
            let content = renderInline(String(text.dropFirst(4)))
            return "<li style=\"list-style: none;\"><input type=\"checkbox\" disabled /> \(content)</li>"
        } else if text.hasPrefix("[x] ") || text.hasPrefix("[X] ") {
            let content = renderInline(String(text.dropFirst(4)))
            return "<li style=\"list-style: none;\"><input type=\"checkbox\" checked disabled /> \(content)</li>"
        }
        return "<li>\(renderInline(text))</li>"
    }
    
    private static func parseTable(lines: [String]) -> (html: String, count: Int)? {
        guard lines.count >= 2 else { return nil }
        let headerLine = lines[0].trimmingCharacters(in: .whitespaces)
        let delimiterLine = lines[1].trimmingCharacters(in: .whitespaces)
        
        let headerCells = splitTableRow(headerLine)
        let delimiterCells = splitTableRow(delimiterLine)
        guard headerCells.count > 0, delimiterCells.count == headerCells.count else { return nil }
        
        var alignments: [String] = []
        for d in delimiterCells {
            let dTrim = d.trimmingCharacters(in: .whitespaces)
            guard dTrim.range(of: #"^:?-+:?$"#, options: .regularExpression) != nil else {
                return nil
            }
            if dTrim.hasPrefix(":") && dTrim.hasSuffix(":") {
                alignments.append("center")
            } else if dTrim.hasSuffix(":") {
                alignments.append("right")
            } else {
                alignments.append("left")
            }
        }
        
        var rowsConsumed = 2
        var bodyRows: [[String]] = []
        while rowsConsumed < lines.count {
            let rowLine = lines[rowsConsumed].trimmingCharacters(in: .whitespaces)
            if !rowLine.hasPrefix("|") || !rowLine.contains("|") {
                break
            }
            let cells = splitTableRow(rowLine)
            bodyRows.append(cells)
            rowsConsumed += 1
        }
        
        var html = "<table>\n<thead>\n<tr>\n"
        for (i, cell) in headerCells.enumerated() {
            let align = i < alignments.count ? alignments[i] : "left"
            html += "<th style=\"text-align: \(align);\">\(renderInline(cell))</th>\n"
        }
        html += "</tr>\n</thead>\n<tbody>\n"
        for row in bodyRows {
            html += "<tr>\n"
            for (i, cell) in row.enumerated() {
                let align = i < alignments.count ? alignments[i] : "left"
                html += "<td style=\"text-align: \(align);\">\(renderInline(cell))</td>\n"
            }
            html += "</tr>\n"
        }
        html += "</tbody>\n</table>"
        return (html, rowsConsumed)
    }
    
    private static func splitTableRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        return trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    // MARK: - Line Numbering Helper
    
    /// Adds line numbers to text
    static func addLineNumbers(to text: String, separator: String) -> String {
        let lineEnding = text.contains("\r\n") ? "\r\n" : (text.contains("\r") ? "\r" : "\n")
        let lines = text.split(separator: /\r\n|\n|\r/, omittingEmptySubsequences: false).map(String.init)
        let lineCount = lines.count
        let digitWidth = max(AppConstants.LineNumbers.minDigits, String(lineCount).count)
        
        var numberedLines: [String] = []
        numberedLines.reserveCapacity(lineCount)
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let paddedNumber = String(format: "%0\(digitWidth)d", lineNumber)
            numberedLines.append("\(paddedNumber)\(separator)\(line)")
        }
        
        var result = numberedLines.joined(separator: lineEnding)
        if text.hasSuffix("\r\n") || text.hasSuffix("\n") || text.hasSuffix("\r") {
            result.append(lineEnding)
        }
        return result
    }
    
    // MARK: - Full HTML Preview Document
    
    /// Renders markdown text into an HTML preview document with an interactive toggle to plain text
    static func renderHTML(markdown: String, with settings: Settings) -> String {
        let renderedBody = markdownToHTML(markdown)
        
        // Prepare plain text view (optionally with line numbers)
        let plainText: String
        if settings.lineNumbersEnabled {
            plainText = addLineNumbers(to: markdown, separator: settings.lineSeparator)
        } else {
            plainText = markdown
        }
        let escapedPlain = escapeHTML(plainText)
        
        let startAsPlain = (settings.defaultView == AppConstants.Markdown.ViewMode.plain.rawValue)
        let renderedDisplay = startAsPlain ? "none" : "block"
        let plainDisplay = startAsPlain ? "block" : "none"
        let initialButtonLabel = startAsPlain ? "Markdown Preview" : "Plain Text"
        let initialCurrentView = startAsPlain ? "plain" : "rendered"
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            :root {
              --bg-color: #ffffff;
              --text-color: #24292f;
              --code-bg: #f6f8fa;
              --border-color: #d0d7de;
              --link-color: #0969da;
              --quote-color: #57606a;
              --table-alt-bg: #f6f8fa;
              --btn-bg: rgba(240, 242, 245, 0.88);
              --btn-border: #d0d7de;
              --btn-hover: #e4e7eb;
              --btn-text: #24292f;
            }
            @media (prefers-color-scheme: dark) {
              :root {
                --bg-color: #0d1117;
                --text-color: #c9d1d9;
                --code-bg: #161b22;
                --border-color: #30363d;
                --link-color: #58a6ff;
                --quote-color: #8b949e;
                --table-alt-bg: #161b22;
                --btn-bg: rgba(33, 38, 45, 0.88);
                --btn-border: #30363d;
                --btn-hover: #3d444d;
                --btn-text: #c9d1d9;
              }
            }
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
              font-size: 14px;
              line-height: 1.6;
              background-color: var(--bg-color);
              color: var(--text-color);
              margin: 0;
              padding: 32px 40px;
              word-wrap: break-word;
            }
            .toolbar-container {
              position: fixed;
              top: 14px;
              right: 18px;
              z-index: 9999;
            }
            .view-toggle-btn {
              display: inline-flex;
              align-items: center;
              gap: 6px;
              padding: 6px 14px;
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
              font-size: 12px;
              font-weight: 500;
              color: var(--btn-text);
              background: var(--btn-bg);
              border: 1px solid var(--btn-border);
              border-radius: 6px;
              cursor: pointer;
              box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
              backdrop-filter: blur(12px);
              -webkit-backdrop-filter: blur(12px);
              transition: all 0.15s ease-in-out;
              user-select: none;
              -webkit-user-select: none;
            }
            .view-toggle-btn:hover {
              background: var(--btn-hover);
            }
            .view-toggle-btn:active {
              transform: scale(0.97);
            }
            #rendered-view {
              display: \(renderedDisplay);
              max-width: 900px;
              margin: 0 auto;
            }
            #plain-view {
              display: \(plainDisplay);
              max-width: 900px;
              margin: 0 auto;
            }
            #plain-view pre {
              font-family: ui-monospace, Menlo, Monaco, "SF Mono", Consolas, "Liberation Mono", "Courier New", monospace;
              font-size: 12px;
              white-space: pre-wrap;
              word-break: break-all;
              line-height: 1.5;
              background-color: transparent;
              border: none;
              padding: 0;
              margin: 0;
            }
            h1, h2, h3, h4, h5, h6 {
              margin-top: 24px;
              margin-bottom: 16px;
              font-weight: 600;
              line-height: 1.25;
            }
            h1 {
              font-size: 2em;
              padding-bottom: 0.3em;
              border-bottom: 1px solid var(--border-color);
            }
            h2 {
              font-size: 1.5em;
              padding-bottom: 0.3em;
              border-bottom: 1px solid var(--border-color);
            }
            h3 { font-size: 1.25em; }
            h4 { font-size: 1em; }
            h5 { font-size: 0.875em; }
            h6 { font-size: 0.85em; color: var(--quote-color); }
            p { margin-top: 0; margin-bottom: 16px; }
            a { color: var(--link-color); text-decoration: none; }
            a:hover { text-decoration: underline; }
            blockquote {
              margin: 0 0 16px 0;
              padding: 0 1em;
              color: var(--quote-color);
              border-left: 0.25em solid var(--border-color);
            }
            code {
              font-family: ui-monospace, Menlo, Monaco, "SF Mono", Consolas, "Liberation Mono", "Courier New", monospace;
              font-size: 85%;
              background-color: var(--code-bg);
              padding: 0.2em 0.4em;
              border-radius: 6px;
            }
            pre {
              margin-top: 0;
              margin-bottom: 16px;
              padding: 16px;
              overflow: auto;
              font-size: 85%;
              line-height: 1.45;
              background-color: var(--code-bg);
              border-radius: 6px;
              border: 1px solid var(--border-color);
            }
            pre code {
              padding: 0;
              background-color: transparent;
              font-size: 100%;
            }
            hr {
              height: 0.25em;
              padding: 0;
              margin: 24px 0;
              background-color: var(--border-color);
              border: 0;
            }
            ul, ol {
              margin-top: 0;
              margin-bottom: 16px;
              padding-left: 2em;
            }
            li + li { margin-top: 0.25em; }
            table {
              border-spacing: 0;
              border-collapse: collapse;
              margin-top: 0;
              margin-bottom: 16px;
              width: 100%;
              overflow: auto;
            }
            table th, table td {
              padding: 6px 13px;
              border: 1px solid var(--border-color);
            }
            table tr {
              background-color: var(--bg-color);
              border-top: 1px solid var(--border-color);
            }
            table tr:nth-child(2n) {
              background-color: var(--table-alt-bg);
            }
            table th {
              font-weight: 600;
              background-color: var(--table-alt-bg);
            }
            input[type="checkbox"] {
              margin-right: 0.3em;
              vertical-align: middle;
            }
            img {
              max-width: 100%;
              box-sizing: border-box;
            }
          </style>
        </head>
        <body>
          <div class="toolbar-container">
            <button id="view-toggle-btn" class="view-toggle-btn" onclick="toggleView()" title="Toggle between Markdown preview and plain text">
              <span id="btn-label">\(initialButtonLabel)</span>
            </button>
          </div>
          
          <div id="rendered-view">
            \(renderedBody)
          </div>
          
          <div id="plain-view">
            <pre><code>\(escapedPlain)</code></pre>
          </div>

          <script>
            var currentView = '\(initialCurrentView)';
            function toggleView() {
              var rendered = document.getElementById('rendered-view');
              var plain = document.getElementById('plain-view');
              var label = document.getElementById('btn-label');
              if (currentView === 'rendered') {
                currentView = 'plain';
                rendered.style.display = 'none';
                plain.style.display = 'block';
                label.textContent = 'Markdown Preview';
              } else {
                currentView = 'rendered';
                rendered.style.display = 'block';
                plain.style.display = 'none';
                label.textContent = 'Plain Text';
              }
            }
            document.addEventListener('keydown', function(e) {
              if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
                if (e.key === 'm' || e.key === 'p' || e.key === 't') {
                  toggleView();
                }
              }
            });
          </script>
        </body>
        </html>
        """
    }
}
