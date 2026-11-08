//
//  MarkdownRendererTests.swift
//  QLStephenSwiftTests
//
//  Created by Takashi Mochizuki on 2026/11/07.
//  Copyright © 2026 MyCometG3. All rights reserved.
//

import XCTest
@testable import QLStephenSwift

final class MarkdownRendererTests: XCTestCase {
    
    // MARK: - Detection Tests
    
    func testMarkdownDetectionByExtension() {
        let mdURL = URL(fileURLWithPath: "/path/to/README.md")
        let markdownURL = URL(fileURLWithPath: "/path/to/doc.markdown")
        let mdownURL = URL(fileURLWithPath: "/path/to/notes.mdown")
        let mkdURL = URL(fileURLWithPath: "/path/to/spec.mkd")
        let txtURL = URL(fileURLWithPath: "/path/to/file.txt")
        let swiftURL = URL(fileURLWithPath: "/path/to/App.swift")
        
        XCTAssertTrue(MarkdownRenderer.isMarkdown(fileURL: mdURL))
        XCTAssertTrue(MarkdownRenderer.isMarkdown(fileURL: markdownURL))
        XCTAssertTrue(MarkdownRenderer.isMarkdown(fileURL: mdownURL))
        XCTAssertTrue(MarkdownRenderer.isMarkdown(fileURL: mkdURL))
        XCTAssertFalse(MarkdownRenderer.isMarkdown(fileURL: txtURL))
        XCTAssertFalse(MarkdownRenderer.isMarkdown(fileURL: swiftURL))
    }
    
    func testMarkdownDetectionExtensionlessDocs() {
        let readmeURL = URL(fileURLWithPath: "/path/to/README")
        let changelogURL = URL(fileURLWithPath: "/path/to/CHANGELOG")
        let contributingURL = URL(fileURLWithPath: "/path/to/CONTRIBUTING")
        let makefileURL = URL(fileURLWithPath: "/path/to/Makefile")
        let scriptURL = URL(fileURLWithPath: "/path/to/install")
        
        let markdownContent = "# Project Title\n\nThis is a sample project.\n\n## Features\n- Feature 1\n- Feature 2"
        let scriptContent = "#!/bin/bash\necho 'hello world'\nexit 0"
        let makefileContent = "# Makefile\nall:\n\tgcc -o prog main.c"
        
        XCTAssertTrue(MarkdownRenderer.isMarkdown(fileURL: readmeURL, sampleText: markdownContent))
        XCTAssertTrue(MarkdownRenderer.isMarkdown(fileURL: changelogURL, sampleText: markdownContent))
        XCTAssertTrue(MarkdownRenderer.isMarkdown(fileURL: contributingURL, sampleText: markdownContent))
        
        // Excluded files should not be treated as markdown
        XCTAssertFalse(MarkdownRenderer.isMarkdown(fileURL: makefileURL, sampleText: makefileContent))
        
        // Scripts with shebang should not be treated as markdown
        XCTAssertFalse(MarkdownRenderer.isMarkdown(fileURL: scriptURL, sampleText: scriptContent))
        XCTAssertFalse(MarkdownRenderer.isMarkdown(fileURL: readmeURL, sampleText: scriptContent))
    }
    
    // MARK: - Heading Tests
    
    func testHeadings() {
        let input = """
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6
        # Heading with Trailing Hash #
        """
        
        let html = MarkdownRenderer.markdownToHTML(input)
        XCTAssertTrue(html.contains("<h1>Heading 1</h1>"))
        XCTAssertTrue(html.contains("<h2>Heading 2</h2>"))
        XCTAssertTrue(html.contains("<h3>Heading 3</h3>"))
        XCTAssertTrue(html.contains("<h4>Heading 4</h4>"))
        XCTAssertTrue(html.contains("<h5>Heading 5</h5>"))
        XCTAssertTrue(html.contains("<h6>Heading 6</h6>"))
        XCTAssertTrue(html.contains("<h1>Heading with Trailing Hash</h1>"))
    }
    
    // MARK: - Inline Formatting Tests
    
    func testInlineFormatting() {
        let input = "This has **bold**, *italic*, `code`, ~~strike~~, and [link](https://example.com)."
        let html = MarkdownRenderer.markdownToHTML(input)
        
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("<em>italic</em>"))
        XCTAssertTrue(html.contains("<code>code</code>"))
        XCTAssertTrue(html.contains("<del>strike</del>"))
        XCTAssertTrue(html.contains("<a href=\"https://example.com\" target=\"_blank\" rel=\"noopener\">link</a>"))
    }
    
    func testImages() {
        let input = "An image: ![Alt Text](https://example.com/pic.png)"
        let html = MarkdownRenderer.markdownToHTML(input)
        XCTAssertTrue(html.contains("<img src=\"https://example.com/pic.png\" alt=\"Alt Text\" />"))
    }
    
    // MARK: - Code Blocks Tests
    
    func testCodeBlocks() {
        let input = """
        ```swift
        func test<T>(val: T) -> Bool {
            return val != nil && true
        }
        ```
        """
        let html = MarkdownRenderer.markdownToHTML(input)
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\">"))
        // HTML characters inside code block must be escaped
        XCTAssertTrue(html.contains("&lt;T&gt;"))
        XCTAssertTrue(html.contains("&amp;&amp;"))
    }
    
    // MARK: - List Tests
    
    func testLists() {
        let unordered = """
        - First
        - Second
        - Third
        """
        let htmlUnordered = MarkdownRenderer.markdownToHTML(unordered)
        XCTAssertTrue(htmlUnordered.contains("<ul>"))
        XCTAssertTrue(htmlUnordered.contains("<li>First</li>"))
        XCTAssertTrue(htmlUnordered.contains("<li>Second</li>"))
        XCTAssertTrue(htmlUnordered.contains("</ul>"))
        
        let ordered = """
        1. Item One
        2. Item Two
        """
        let htmlOrdered = MarkdownRenderer.markdownToHTML(ordered)
        XCTAssertTrue(htmlOrdered.contains("<ol>"))
        XCTAssertTrue(htmlOrdered.contains("<li>Item One</li>"))
        XCTAssertTrue(htmlOrdered.contains("<li>Item Two</li>"))
        XCTAssertTrue(htmlOrdered.contains("</ol>"))
        
        let taskList = """
        - [ ] Pending task
        - [x] Completed task
        """
        let htmlTask = MarkdownRenderer.markdownToHTML(taskList)
        XCTAssertTrue(htmlTask.contains("<input type=\"checkbox\" disabled /> Pending task"))
        XCTAssertTrue(htmlTask.contains("<input type=\"checkbox\" checked disabled /> Completed task"))
    }
    
    // MARK: - Table Tests
    
    func testTables() {
        let input = """
        | Name | Age | Role |
        | :--- | :---: | ---: |
        | Alice | 30 | Engineer |
        | Bob | 25 | Designer |
        """
        let html = MarkdownRenderer.markdownToHTML(input)
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("<thead>"))
        XCTAssertTrue(html.contains("<th style=\"text-align: left;\">Name</th>"))
        XCTAssertTrue(html.contains("<th style=\"text-align: center;\">Age</th>"))
        XCTAssertTrue(html.contains("<th style=\"text-align: right;\">Role</th>"))
        XCTAssertTrue(html.contains("<tbody>"))
        XCTAssertTrue(html.contains("<td style=\"text-align: left;\">Alice</td>"))
        XCTAssertTrue(html.contains("</table>"))
    }
    
    // MARK: - Blockquote Tests
    
    func testBlockquotes() {
        let input = "> This is a quote\n> Second line of quote"
        let html = MarkdownRenderer.markdownToHTML(input)
        XCTAssertTrue(html.contains("<blockquote><p>This is a quote Second line of quote</p></blockquote>"))
    }
    
    // MARK: - Horizontal Rule Tests
    
    func testHorizontalRule() {
        let input = "Before\n\n---\n\nAfter"
        let html = MarkdownRenderer.markdownToHTML(input)
        XCTAssertTrue(html.contains("<hr />"))
    }
    
    // MARK: - Full HTML Document & Toggle Tests
    
    func testRenderHTMLDocumentDefaultRendered() {
        let markdown = "# Hello\n\nWorld"
        let settings = MarkdownRenderer.Settings(
            enabled: true,
            defaultView: "rendered",
            lineNumbersEnabled: false,
            lineSeparator: " "
        )
        let html = MarkdownRenderer.renderHTML(markdown: markdown, with: settings)
        
        // Structure checks
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<div class=\"toolbar-container\">"))
        XCTAssertTrue(html.contains("id=\"view-toggle-btn\""))
        XCTAssertTrue(html.contains("<span id=\"btn-label\">Plain Text</span>"))
        XCTAssertTrue(html.contains("<div id=\"rendered-view\">"))
        XCTAssertTrue(html.contains("<div id=\"plain-view\">"))
        XCTAssertTrue(html.contains("var currentView = 'rendered';"))
        XCTAssertTrue(html.contains("function toggleView()"))
        XCTAssertTrue(html.contains("<h1>Hello</h1>"))
    }
    
    func testRenderHTMLDocumentDefaultPlain() {
        let markdown = "# Hello\n\nWorld"
        let settings = MarkdownRenderer.Settings(
            enabled: true,
            defaultView: "plain",
            lineNumbersEnabled: false,
            lineSeparator: " "
        )
        let html = MarkdownRenderer.renderHTML(markdown: markdown, with: settings)
        
        XCTAssertTrue(html.contains("<span id=\"btn-label\">Markdown Preview</span>"))
        XCTAssertTrue(html.contains("var currentView = 'plain';"))
    }
    
    func testRenderHTMLDocumentWithLineNumbers() {
        let markdown = "line 1\nline 2"
        let settings = MarkdownRenderer.Settings(
            enabled: true,
            defaultView: "rendered",
            lineNumbersEnabled: true,
            lineSeparator: " "
        )
        let html = MarkdownRenderer.renderHTML(markdown: markdown, with: settings)
        // Plain text section should contain line numbers
        XCTAssertTrue(html.contains("0001 line 1"))
        XCTAssertTrue(html.contains("0002 line 2"))
    }
}
