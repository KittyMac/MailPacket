import Foundation
import Flynn
import Hitch

// Composes rfc5322 compliant messages suitable for handing to SMTP.beSend()
// or IMAP.beAppend(). Pure swift, no libetpan, so it is available on every
// platform.

public struct EML: Codable {
    
    public struct Address: Codable, Equatable {
        public let name: String?
        public let email: String
        
        public init(_ email: String,
                    name: String? = nil) {
            self.email = EML.sanitize(email)
            if let name = name, name.isEmpty == false {
                self.name = EML.sanitize(name)
            } else {
                self.name = nil
            }
        }
    }
    
    public struct Header: Codable, Equatable {
        public let name: String
        public let value: String
        
        public init(_ name: String,
                    _ value: String) {
            self.name = EML.sanitize(name)
            self.value = EML.sanitize(value)
        }
    }
    
    public var from: Address
    public var to: [Address]
    public var cc: [Address]
    public var bcc: [Address]
    public var replyTo: [Address]
    public var subject: String
    public var body: String
    public var date: Date
    public var timeZone: TimeZone
    
    // always present; generated from the sender's domain when not provided, so
    // the caller can record it before the message is ever sent
    public var messageID: String
    
    // threading
    public var inReplyTo: String?
    public var references: [String]
    
    public var userAgent: String?
    public var extraHeaders: [Header]
    
    public init(from: Address,
                to: [Address],
                subject: String,
                body: String,
                cc: [Address] = [],
                bcc: [Address] = [],
                replyTo: [Address] = [],
                date: Date = Date(),
                timeZone: TimeZone = TimeZone.current,
                messageID: String? = nil,
                inReplyTo: String? = nil,
                references: [String] = [],
                userAgent: String? = "MailPacket",
                extraHeaders: [Header] = []) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.replyTo = replyTo
        self.subject = EML.sanitize(subject)
        self.body = body
        self.date = date
        self.timeZone = timeZone
        self.messageID = EML.sanitize(messageID ?? EML.generateMessageID(from: from))
        self.inReplyTo = inReplyTo.map { EML.sanitize($0) }
        self.references = references.map { EML.sanitize($0) }
        self.userAgent = userAgent.map { EML.sanitize($0) }
        self.extraHeaders = extraHeaders
    }
    
    /// The smtp envelope recipients; to + cc + bcc. Bcc intentionally appears
    /// here and never in the message headers.
    public var recipients: [String] {
        return (to + cc + bcc).map { $0.email }
    }
    
    /// The composed rfc5322 message, crlf line endings throughout.
    public func eml() -> String {
        var lines: [String] = []
        
        lines.append(EML.fold(name: "Date", value: EML.format(date: date, timeZone: timeZone)))
        lines.append(EML.fold(name: "From", value: EML.format(addresses: [from])))
        if to.isEmpty == false {
            lines.append(EML.fold(name: "To", value: EML.format(addresses: to)))
        }
        if cc.isEmpty == false {
            lines.append(EML.fold(name: "Cc", value: EML.format(addresses: cc)))
        }
        if replyTo.isEmpty == false {
            lines.append(EML.fold(name: "Reply-To", value: EML.format(addresses: replyTo)))
        }
        lines.append(EML.fold(name: "Subject", value: EML.encodeIfNeeded(subject)))
        lines.append(EML.fold(name: "Message-ID", value: messageID))
        
        if let inReplyTo = inReplyTo {
            lines.append(EML.fold(name: "In-Reply-To", value: inReplyTo))
        }
        if references.isEmpty == false {
            lines.append(EML.fold(name: "References", value: references.joined(separator: " ")))
        }
        if let userAgent = userAgent {
            lines.append(EML.fold(name: "User-Agent", value: EML.encodeIfNeeded(userAgent)))
        }
        
        for header in extraHeaders {
            lines.append(EML.fold(name: header.name, value: EML.encodeIfNeeded(header.value)))
        }
        
        let encoded = EML.encode(body: body)
        
        lines.append("MIME-Version: 1.0")
        lines.append("Content-Type: text/plain; charset=\(encoded.charset)")
        lines.append("Content-Transfer-Encoding: \(encoded.encoding)")
        
        return lines.joined(separator: "\r\n") + "\r\n\r\n" + encoded.body
    }
    
    // MARK: - internals
    
    // header values may never contain cr or lf; allowing them would let a
    // subject or display name inject arbitrary headers
    internal static func sanitize(_ value: String) -> String {
        guard value.contains("\r") || value.contains("\n") else {
            return value.trimmingCharacters(in: .whitespaces)
        }
        return value
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
    
    internal static func generateMessageID(from: Address) -> String {
        let domain = from.email.components(separatedBy: "@").last ?? "localhost"
        return "<\(UUID().uuidString.lowercased())@\(domain.isEmpty ? "localhost" : domain)>"
    }
    
    internal static func format(date: Date,
                                timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss ZZZ"
        return formatter.string(from: date)
    }
    
    private static func isAscii(_ value: String) -> Bool {
        return value.utf8.allSatisfy { $0 < 0x80 }
    }
    
    // rfc2047 encoded word, split so no single word exceeds 75 characters and
    // no multibyte character is split across words
    internal static func encodedWord(_ value: String) -> String {
        var words: [String] = []
        var chunk = ""
        var chunkBytes = 0
        
        for character in value {
            let bytes = String(character).utf8.count
            if chunkBytes + bytes > 45 {
                words.append(chunk)
                chunk = ""
                chunkBytes = 0
            }
            chunk.append(character)
            chunkBytes += bytes
        }
        if chunk.isEmpty == false {
            words.append(chunk)
        }
        
        return words
            .map { "=?utf-8?B?\(Data($0.utf8).base64EncodedString())?=" }
            .joined(separator: "\r\n ")
    }
    
    internal static func encodeIfNeeded(_ value: String) -> String {
        guard isAscii(value) == false else { return value }
        return encodedWord(value)
    }
    
    internal static func format(address: Address) -> String {
        guard let name = address.name else { return address.email }
        
        if isAscii(name) == false {
            return "\(encodedWord(name)) <\(address.email)>"
        }
        
        let specials = CharacterSet(charactersIn: "()<>@,;:\\\".[]")
        if name.rangeOfCharacter(from: specials) != nil {
            let quoted = name
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(quoted)\" <\(address.email)>"
        }
        
        return "\(name) <\(address.email)>"
    }
    
    internal static func format(addresses: [Address]) -> String {
        return addresses
            .map { format(address: $0) }
            .joined(separator: ", ")
    }
    
    // rfc5322 recommends header lines stay under 78 characters; fold on
    // existing whitespace when we can, and never fold a line that is already
    // a single unbreakable token
    internal static func fold(name: String,
                              value: String) -> String {
        var result = "\(name):"
        var length = result.count
        
        // an already folded value (encoded words) arrives with its own crlf,
        // measure from the last line of it
        for token in value.components(separatedBy: " ") {
            if length + token.count + 1 > 78 && length > name.count + 1 {
                result += "\r\n \(token)"
                length = 1 + token.count
            } else {
                result += " \(token)"
                length += 1 + token.count
            }
            if let lastLine = result.components(separatedBy: "\r\n").last {
                length = lastLine.count
            }
        }
        
        return result
    }
    
    internal static func encode(body: String) -> (charset: String, encoding: String, body: String) {
        let normalized = body
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "\r\n")
        
        let bytes = Array(normalized.utf8)
        let ascii = bytes.allSatisfy { $0 < 0x80 }
        
        // rfc5322 hard limit is 998 characters per line
        var longestLine = 0
        var currentLine = 0
        for byte in bytes {
            if byte == 0x0A {
                currentLine = 0
            } else if byte != 0x0D {
                currentLine += 1
                longestLine = max(longestLine, currentLine)
            }
        }
        
        if ascii && longestLine <= 998 {
            var body = normalized
            if body.hasSuffix("\r\n") == false {
                body += "\r\n"
            }
            return ("us-ascii", "7bit", body)
        }
        
        let base64 = Data(bytes).base64EncodedString()
        var wrapped: [String] = []
        var index = base64.startIndex
        while index < base64.endIndex {
            let end = base64.index(index, offsetBy: 76, limitedBy: base64.endIndex) ?? base64.endIndex
            wrapped.append(String(base64[index..<end]))
            index = end
        }
        
        return ("utf-8", "base64", wrapped.joined(separator: "\r\n") + "\r\n")
    }
}
