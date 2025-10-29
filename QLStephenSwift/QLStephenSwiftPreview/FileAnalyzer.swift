//
//  FileAnalyzer.swift
//  QLStephenSwiftPreview
//
//  Created by Takashi Mochizuki on 2025/10/29.
//

import Foundation

struct FileAnalyzer {
    private static let maxBytesToCheck = 8192 // 8KB for initial analysis
    
    struct AnalysisResult {
        let isTextFile: Bool
        let encoding: String.Encoding
        let mimeType: String
    }
    
    static func analyze(fileURL: URL) throws -> AnalysisResult {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else {
            throw AnalysisError.cannotOpenFile
        }
        defer { try? fileHandle.close() }
        
        // Read initial bytes for analysis
        guard let data = try? fileHandle.read(upToCount: maxBytesToCheck),
              !data.isEmpty else {
            throw AnalysisError.cannotReadFile
        }
        
        // Check if it's a text file
        guard isTextData(data) else {
            return AnalysisResult(isTextFile: false, encoding: .utf8, mimeType: "application/octet-stream")
        }
        
        // Detect encoding
        let encoding = detectEncoding(data)
        
        return AnalysisResult(isTextFile: true, encoding: encoding, mimeType: "text/plain")
    }
    
    private static func isTextData(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        var controlCharCount = 0
        var nullByteCount = 0
        let checkLength = min(bytes.count, 512)
        
        for i in 0..<checkLength {
            let byte = bytes[i]
            
            // Check for null bytes (strong indicator of binary)
            if byte == 0x00 {
                nullByteCount += 1
                if nullByteCount > 0 {
                    return false
                }
            }
            
            // Allow common whitespace and printable ASCII
            if byte < 0x20 {
                // Allow: TAB(0x09), LF(0x0A), CR(0x0D), FF(0x0C)
                if byte != 0x09 && byte != 0x0A && byte != 0x0D && byte != 0x0C {
                    controlCharCount += 1
                }
            }
        }
        
        // If more than 30% are control characters, likely binary
        let controlRatio = Double(controlCharCount) / Double(checkLength)
        if controlRatio > 0.3 {
            return false
        }
        
        return true
    }
    
    private static func detectEncoding(_ data: Data) -> String.Encoding {
        // Check for UTF-8 BOM
        if data.count >= 3 {
            let bom = data.prefix(3)
            if bom[0] == 0xEF && bom[1] == 0xBB && bom[2] == 0xBF {
                return .utf8
            }
        }
        
        // Check for UTF-16 BOM
        if data.count >= 2 {
            let bom = data.prefix(2)
            if bom[0] == 0xFE && bom[1] == 0xFF {
                return .utf16BigEndian
            }
            if bom[0] == 0xFF && bom[1] == 0xFE {
                return .utf16LittleEndian
            }
        }
        
        // Try to decode as UTF-8 (strict validation)
        if let str = String(data: data, encoding: .utf8), 
           isValidUTF8(data) {
            return .utf8
        }
        
        // Try Japanese encodings before ISO Latin 1
        // (ISO Latin 1 accepts almost any byte sequence)
        
        // Try Japanese EUC
        if String(data: data, encoding: .japaneseEUC) != nil {
            return .japaneseEUC
        }
        
        // Try Shift-JIS
        if String(data: data, encoding: .shiftJIS) != nil {
            return .shiftJIS
        }
        
        // Try ISO Latin 1 (fallback for many European languages)
        if String(data: data, encoding: .isoLatin1) != nil {
            return .isoLatin1
        }
        
        // Default to UTF-8
        return .utf8
    }
    
    private static func isValidUTF8(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        var i = 0
        
        while i < bytes.count {
            let byte = bytes[i]
            
            // Single byte (ASCII)
            if byte < 0x80 {
                i += 1
                continue
            }
            
            // Multi-byte sequence
            var extraBytes = 0
            if (byte & 0xE0) == 0xC0 {
                extraBytes = 1
            } else if (byte & 0xF0) == 0xE0 {
                extraBytes = 2
            } else if (byte & 0xF8) == 0xF0 {
                extraBytes = 3
            } else {
                return false // Invalid UTF-8 start byte
            }
            
            // Check continuation bytes
            for j in 1...extraBytes {
                if i + j >= bytes.count {
                    return false
                }
                if (bytes[i + j] & 0xC0) != 0x80 {
                    return false // Invalid continuation byte
                }
            }
            
            i += extraBytes + 1
        }
        
        return true
    }
}

enum AnalysisError: Error {
    case cannotOpenFile
    case cannotReadFile
}
