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
        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = resourceValues.fileSize else {
            throw AnalysisError.cannotReadFile
        }
        
        // Determine how much data to read based on file size
        let shouldReadFull = fileSize <= maxFullReadBytes
        let dataToAnalyze: Data
        
        if shouldReadFull {
            // Read entire file for small files
            guard let fullData = try? Data(contentsOf: fileURL), !fullData.isEmpty else {
                throw AnalysisError.cannotReadFile
            }
            dataToAnalyze = fullData
        } else {
            // Read only sample for large files
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
        let fileType = try analyzeFile(fileURL: fileURL)
        
        switch fileType {
        case .text(let encoding, _):
            return AnalysisResult(isTextFile: true, encoding: encoding, mimeType: "text/plain")
        case .binary:
            return AnalysisResult(isTextFile: false, encoding: .utf8, mimeType: "application/octet-stream")
        }
    }
    
    private static func isBinaryData(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        var suspiciousCount = 0
        let checkLength = min(bytes.count, maxBytesToCheck)
        
        for i in 0..<checkLength {
            let byte = bytes[i]
            
            // Check for null bytes (strong indicator of binary)
            if byte == 0x00 {
                suspiciousCount += 1
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
    
    private static func detectEncodingAndDecode(data: Data) -> (String.Encoding, String)? {
        // 1. Check for BOM (highest priority)
        if let (encoding, bomSize) = detectBOM(data) {
            let dataWithoutBOM = data.dropFirst(bomSize)
            if let text = String(data: dataWithoutBOM, encoding: encoding) {
                return (encoding, text)
            }
        }
        
        // 2. Use Foundation/ICU-based encoding detection
        if let detected = detectEncodingWithICU(data) {
            if let text = String(data: data, encoding: detected) {
                return (detected, text)
            }
        }
        
        // 3. Fallback with priority order
        let fallbackEncodings: [String.Encoding] = [.utf8, .shiftJIS, .japaneseEUC, .isoLatin1]
        
        for encoding in fallbackEncodings {
            if let text = String(data: data, encoding: encoding) {
                return (encoding, text)
            }
        }
        
        // 4. Last resort: lossy UTF-8
        if let text = String(data: data, encoding: .utf8) {
            return (.utf8, text)
        }
        
        // Could not decode
        return nil
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
        
        // UTF-16 LE BOM - only if NOT UTF-32 LE
        // Verify that if we have 4 bytes, bytes[2] and bytes[3] are NOT both 0x00
        if bytes.count >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE {
            if bytes.count >= 4 && bytes[2] == 0x00 && bytes[3] == 0x00 {
                // This is actually UTF-32 LE, already handled above
                return nil
            }
            return (.utf16LittleEndian, 2)
        }
        
        return nil
    }
    
    private static func detectEncodingWithICU(_ data: Data) -> String.Encoding? {
        var convertedString: NSString?
        var usedLossyConversion: ObjCBool = false
        
        let encoding = NSString.stringEncoding(
            for: data,
            encodingOptions: [
                .allowLossy: false,
                .suggestedEncodings: [NSNumber(value: String.Encoding.utf8.rawValue)]
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
