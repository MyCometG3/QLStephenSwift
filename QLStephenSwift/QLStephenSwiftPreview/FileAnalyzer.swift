//
//  FileAnalyzer.swift
//  QLStephenSwiftPreview
//
//  Created by Takashi Mochizuki on 2025/10/29.
//  Copyright © 2025 MyCometG3. All rights reserved.
//

import Foundation

struct FileAnalyzer {
    private static let maxBytesToCheck = 8192 // 8KB for initial analysis
    private static let maxFullReadBytes = 5 * 1024 * 1024 // 5MB threshold for full file read
    private static let binaryThreshold = 0.3 // 30% threshold for binary detection
    
    // Default encoding suggestion array for ICU detection
    // Can be customized via the suggestedEncodings parameter in detection methods
    // Includes common Japanese encodings to improve detection accuracy
    private static let defaultSuggestedEncodings: [String.Encoding] = [
        .utf8,
        .utf16LittleEndian,
        .utf16BigEndian,
        .utf32LittleEndian,
        .utf32BigEndian,
        .iso2022JP,        // Japanese JIS encoding (ISO-2022-JP)
        .japaneseEUC,      // Japanese EUC encoding
        .shiftJIS          // Japanese Shift-JIS encoding
    ]
    
    // Default fallback encoding array
    // These are tried in order if BOM and ICU detection fail
    // Ordered by strictness and regional relevance to minimize false positives
    // Priority: Japanese > Korean > Chinese > Western
    private static let defaultFallbackEncodings: [String.Encoding] = [
        .iso2022JP,        // Japanese JIS - highly structured, low false positive rate
        .japaneseEUC,      // Japanese EUC-JP
        .shiftJIS,         // Japanese Shift-JIS
        .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_KR.rawValue))),  // Korean EUC-KR
        .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))),  // Chinese GB18030 (superset of GB2312)
        .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue))),  // Traditional Chinese Big5
        .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_2312_80.rawValue))),  // Chinese GB2312 (legacy)
        .windowsCP1252,    // Western European (Windows)
        .macOSRoman        // Western European (Mac)
    ]
    
    enum FileType {
        case text(encoding: String.Encoding, string: String)
        case binary
    }
    
    struct AnalysisResult {
        let isTextFile: Bool
        let encoding: String.Encoding
        let mimeType: String
    }
    
    static func analyzeFile(fileURL: URL) throws -> FileType {
        // Get file size
        let fileSize = try getFileSize(for: fileURL)
        
        // Determine how much data to read based on file size
        // Note: For files ≤5MB, entire file is loaded into memory to ensure accurate
        // encoding detection and complete text decoding. For larger files, only the
        // first 8KB is read to minimize memory usage. This trades memory for accuracy.
        let shouldReadFull = fileSize <= maxFullReadBytes
        let dataToAnalyze: Data
        
        if shouldReadFull {
            // Read entire file for small files (≤5MB)
            // Memory impact: Up to 5MB per file. QuickLook typically processes one file
            // at a time, so concurrent memory pressure is minimal.
            guard let fullData = try? Data(contentsOf: fileURL), !fullData.isEmpty else {
                throw AnalysisError.cannotReadFile
            }
            dataToAnalyze = fullData
        } else {
            // Read only sample for large files (>5MB)
            // Memory impact: Fixed 8KB per file regardless of file size
            guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else {
                throw AnalysisError.cannotOpenFile
            }
            defer { try? fileHandle.close() }
            
            guard let sampleData = try? fileHandle.read(upToCount: maxBytesToCheck),
                  !sampleData.isEmpty else {
                throw AnalysisError.cannotReadFile
            }
            dataToAnalyze = sampleData
        }
        
        // Apply cheap binary heuristic first
        if isBinaryData(dataToAnalyze) {
            return .binary
        }
        
        // Detect encoding and decode
        if let (encoding, text) = detectEncodingAndDecode(data: dataToAnalyze) {
            return .text(encoding: encoding, string: text)
        }
        
        return .binary
    }
    
    static func analyze(fileURL: URL) throws -> AnalysisResult {
        // Get file size
        // For encoding detection, we only need a sample
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else {
            throw AnalysisError.cannotOpenFile
        }
        defer { try? fileHandle.close() }
        
        guard let sampleData = try? fileHandle.read(upToCount: maxBytesToCheck),
              !sampleData.isEmpty else {
            throw AnalysisError.cannotReadFile
        }
        
        // Apply cheap binary heuristic first
        if isBinaryData(sampleData) {
            return AnalysisResult(isTextFile: false, encoding: .utf8, mimeType: "application/octet-stream")
        }
        
        // Detect encoding without decoding full text
        let encoding = detectEncoding(data: sampleData)
        return AnalysisResult(isTextFile: true, encoding: encoding, mimeType: "text/plain")
    }
    
    private static func detectEncoding(data: Data, suggestedEncodings: [String.Encoding]? = nil, fallbackEncodings: [String.Encoding]? = nil) -> String.Encoding {
        // Reuse the encoding detection logic from detectEncodingAndDecode
        // This avoids code duplication while keeping the API surface appropriate
        if let (encoding, _) = detectEncodingAndDecode(data: data, suggestedEncodings: suggestedEncodings, fallbackEncodings: fallbackEncodings) {
            return encoding
        }
        // This should never happen as detectEncodingAndDecode always returns something
        return .utf8
    }
    
    private static func getFileSize(for fileURL: URL) throws -> Int {
        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = resourceValues.fileSize else {
            throw AnalysisError.cannotReadFile
        }
        return fileSize
    }
    
    private static func isBinaryData(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        var suspiciousCount = 0
        let checkLength = min(bytes.count, maxBytesToCheck)
        
        for i in 0..<checkLength {
            let byte = bytes[i]
            
            // Check for null bytes (strong indicator of binary)
            if byte == 0x00 {
                // Immediate binary detection on null byte
                return true
            } else if byte < 0x20 {
                // Check for control characters (excluding common whitespace)
                // Allow: TAB(0x09), LF(0x0A), CR(0x0D), FF(0x0C)
                if byte != 0x09 && byte != 0x0A && byte != 0x0D && byte != 0x0C {
                    suspiciousCount += 1
                }
            }
        }
        
        // If more than threshold are suspicious bytes, likely binary
        let suspiciousRatio = Double(suspiciousCount) / Double(checkLength)
        return suspiciousRatio > binaryThreshold
    }
    
    private static func detectEncodingAndDecode(data: Data, suggestedEncodings: [String.Encoding]? = nil, fallbackEncodings: [String.Encoding]? = nil) -> (String.Encoding, String)? {
        let suggested = suggestedEncodings ?? defaultSuggestedEncodings
        let fallbacks = fallbackEncodings ?? defaultFallbackEncodings
        
        // 1. Check for BOM (highest priority)
        // BOM provides definitive encoding information
        if let (encoding, bomSize) = detectBOM(data) {
            let dataWithoutBOM = Data(data.dropFirst(bomSize))
            if let text = String(data: dataWithoutBOM, encoding: encoding) {
                return (encoding, text)
            }
            // BOM detected but decoding failed, try fallback with original data
            // (keeping BOM in case another encoding can decode it successfully)
        }
        
        // 2. Strict UTF-8 validation (without BOM)
        // Performed before ICU detection to ensure high-confidence UTF-8 detection
        // This prevents false positives from ICU's heuristic-based detection
        if isStrictUTF8(data) {
            if let text = String(data: data, encoding: .utf8) {
                return (.utf8, text)
            }
        }
        
        // 3. Use Foundation/ICU-based encoding detection
        // ICU uses statistical analysis and heuristics for encoding detection
        if let detected = detectEncodingWithICU(data, suggestedEncodings: suggested) {
            if let text = String(data: data, encoding: detected) {
                return (detected, text)
            }
        }
        
        // 4. Fallback with priority order
        for encoding in fallbacks {
            if let text = String(data: data, encoding: encoding) {
                return (encoding, text)
            }
        }
        
        // 4. Last resort: lossy UTF-8 using different initializer
        // Note: String(decoding:as:) performs lossy conversion, replacing invalid
        // UTF-8 sequences with replacement characters (U+FFFD). This ensures we
        // always return something, but may produce gibberish for truly binary data
        // or text in undetected encodings. This should only be reached after the
        // binary heuristic has already passed, so the data is likely text-like.
        let text = String(decoding: data, as: UTF8.self)
        return (.utf8, text)
    }
    
    /// Performs strict UTF-8 validation without BOM
    /// This validates the byte sequence structure according to UTF-8 specification
    /// - Parameter data: Data to validate
    /// - Returns: true if data is valid UTF-8 with no encoding errors
    /// - Note: Rejects overlong encodings, invalid code points (surrogates, out-of-range)
    private static func isStrictUTF8(_ data: Data) -> Bool {
        var position = 0
        let bytes = [UInt8](data)
        let length = bytes.count
        
        while position < length {
            let byte = bytes[position]
            
            // ASCII range (0x00-0x7F) - single byte
            if byte <= 0x7F {
                position += 1
                continue
            }
            
            // Determine sequence length and validate leading byte
            let sequenceLength: Int
            let mask: UInt8
            
            if (byte & 0b11100000) == 0b11000000 {
                // 2-byte sequence (110xxxxx)
                sequenceLength = 2
                mask = 0b00011111
            } else if (byte & 0b11110000) == 0b11100000 {
                // 3-byte sequence (1110xxxx)
                sequenceLength = 3
                mask = 0b00001111
            } else if (byte & 0b11111000) == 0b11110000 {
                // 4-byte sequence (11110xxx)
                sequenceLength = 4
                mask = 0b00000111
            } else {
                // Invalid leading byte
                return false
            }
            
            // Check if we have enough bytes
            if position + sequenceLength > length {
                return false
            }
            
            // Validate continuation bytes (10xxxxxx)
            for i in 1..<sequenceLength {
                if (bytes[position + i] & 0b11000000) != 0b10000000 {
                    return false
                }
            }
            
            // Check for overlong encodings and invalid code points
            let codePoint = computeUTF8CodePoint(bytes: bytes, start: position, length: sequenceLength, mask: mask)
            if !isValidUTF8CodePoint(codePoint: codePoint, sequenceLength: sequenceLength) {
                return false
            }
            
            position += sequenceLength
        }
        
        return true
    }
    
    /// Computes the Unicode code point from a UTF-8 byte sequence
    /// - Parameters:
    ///   - bytes: The byte array
    ///   - start: Starting position of the sequence
    ///   - length: Length of the sequence (2, 3, or 4 bytes)
    ///   - mask: Bit mask for the leading byte
    /// - Returns: The decoded Unicode code point
    private static func computeUTF8CodePoint(bytes: [UInt8], start: Int, length: Int, mask: UInt8) -> UInt32 {
        var codePoint = UInt32(bytes[start] & mask)
        for i in 1..<length {
            codePoint = (codePoint << 6) | UInt32(bytes[start + i] & 0b00111111)
        }
        return codePoint
    }
    
    /// Validates a UTF-8 code point for overlong encodings and invalid ranges
    /// - Parameters:
    ///   - codePoint: The code point to validate
    ///   - sequenceLength: The byte sequence length used to encode it
    /// - Returns: true if the code point is valid
    private static func isValidUTF8CodePoint(codePoint: UInt32, sequenceLength: Int) -> Bool {
        // Check for overlong encodings (using more bytes than necessary)
        switch sequenceLength {
        case 2:
            if codePoint < 0x80 { return false }
        case 3:
            if codePoint < 0x800 { return false }
        case 4:
            if codePoint < 0x10000 { return false }
        default:
            break
        }
        
        // Check for invalid ranges
        // Surrogate pairs (U+D800 to U+DFFF) - reserved for UTF-16
        if codePoint >= 0xD800 && codePoint <= 0xDFFF {
            return false
        }
        
        // Above valid Unicode range (> U+10FFFF)
        if codePoint > 0x10FFFF {
            return false
        }
        
        return true
    }
    
    private static func detectBOM(_ data: Data) -> (String.Encoding, Int)? {
        let bytes = [UInt8](data.prefix(4))
        
        // UTF-32 BE BOM
        if bytes.count >= 4 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF {
            return (.utf32BigEndian, 4)
        }
        
        // UTF-32 LE BOM - must check all 4 bytes before checking UTF-16 LE
        if bytes.count >= 4 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00 {
            return (.utf32LittleEndian, 4)
        }
        
        // UTF-8 BOM
        if bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF {
            return (.utf8, 3)
        }
        
        // UTF-16 BE BOM
        if bytes.count >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF {
            return (.utf16BigEndian, 2)
        }
        
        // UTF-16 LE BOM
        // If we have 4 bytes and they match UTF-32 LE pattern, it was already handled above
        if bytes.count >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE {
            return (.utf16LittleEndian, 2)
        }
        
        return nil
    }
    
    private static func detectEncodingWithICU(_ data: Data, suggestedEncodings: [String.Encoding]) -> String.Encoding? {
        var convertedString: NSString?
        var usedLossyConversion: ObjCBool = false
        
        // Convert String.Encoding array to NSNumber array for ICU
        let suggestedEncodingNumbers = suggestedEncodings.map { NSNumber(value: $0.rawValue) }
        
        let encoding = NSString.stringEncoding(
            for: data,
            encodingOptions: [
                .allowLossyKey: false,
                .suggestedEncodingsKey: suggestedEncodingNumbers
            ],
            convertedString: &convertedString,
            usedLossyConversion: &usedLossyConversion
        )
        
        // If detection succeeded and conversion was not lossy, use this encoding
        if encoding != 0 && !usedLossyConversion.boolValue {
            return String.Encoding(rawValue: encoding)
        }
        
        return nil
    }
}

enum AnalysisError: Error {
    case cannotOpenFile
    case cannotReadFile
}
