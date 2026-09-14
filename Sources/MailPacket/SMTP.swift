import Foundation
import Flynn
import Hitch

#if !canImport(libetpan)
public class SMTP: Actor {
    
    public var unsafeConnectionInfo: ConnectionInfo? = nil
    
    public enum Security: Int, Codable {
        case ssl        // implicit tls, typically port 465
        case startTLS   // explicit tls, typically port 587
    }
    
    public struct ConnectionInfo: Codable {
        public let domain: String
        public let port: Int
        public let account: String
        public let password: String
        public let oauth2: Bool
        public let security: Security
        
        public init(domain: String,
                    port: Int,
                    account: String,
                    password: String,
                    oauth2: Bool,
                    security: Security) {
            self.domain = domain
            self.port = port
            self.account = account
            self.password = password
            self.oauth2 = oauth2
            self.security = security
        }
    }
    
    internal func _beClose(_ returnCallback: @escaping () -> ()) {
        returnCallback()
    }
    
    internal func _beGetConnection() -> ConnectionInfo? {
        return nil
    }
    
    internal func _beConnect(domain: String,
                             port: Int,
                             account: String,
                             password: String,
                             oauth2: Bool,
                             security: Security,
                             _ returnCallback: @escaping (String?) -> ()) {
        return returnCallback("unsupported platform")
    }
    
    internal func _beSend(from: String,
                          recipients: [String],
                          eml: String,
                          _ returnCallback: @escaping (String?) -> ()) {
        return returnCallback("unsupported platform")
    }
    
    internal func _beSend(eml: EML,
                          _ returnCallback: @escaping (String?) -> ()) {
        return returnCallback("unsupported platform")
    }
}
#endif

#if canImport(libetpan)
import libetpan

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class SMTP: Actor {
    
    public enum Security: Int, Codable {
        case ssl        // implicit tls, typically port 465
        case startTLS   // explicit tls, typically port 587
    }
    
    public struct ConnectionInfo: Codable {
        public let domain: String
        public let port: Int
        public let account: String
        public let password: String
        public let oauth2: Bool
        public let security: Security
        
        public init(domain: String,
                    port: Int,
                    account: String,
                    password: String,
                    oauth2: Bool,
                    security: Security) {
            self.domain = domain
            self.port = port
            self.account = account
            self.password = password
            self.oauth2 = oauth2
            self.security = security
        }
    }
    
    private let queue: OperationQueue
    
    private let smtp: UnsafeMutableRawPointer?
    
    public var unsafeConnectionInfo: ConnectionInfo?
    
    public override init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        smtp = cmailsmtp_new()
    }
    
    deinit {
        cmailsmtp_free(smtp)
    }
    
    private func smtpResponse() -> String? {
        guard let cString = csmtp_response(self.smtp) else { return nil }
        let response = Hitch(own: cString)
        return response.toString()
    }
    
    internal func _beClose(_ returnCallback: @escaping () -> ()) {
        cmailsmtp_quit(smtp)
        returnCallback()
    }
    
    internal func _beGetConnection() -> ConnectionInfo? {
        return unsafeConnectionInfo
    }
    
    internal func _beConnect(domain: String,
                             port: Int,
                             account: String,
                             password: String,
                             oauth2: Bool,
                             security: Security,
                             _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            var result: CSMTPError = 0
            
            switch security {
            case .ssl:
                result = cmailsmtp_ssl_connect(self.smtp, domain, UInt16(port))
            case .startTLS:
                result = cmailsmtp_starttls_connect(self.smtp, domain, UInt16(port))
            }
            
            if let error = result.toSMTPString(self.smtpResponse()) {
                return returnCallback(error)
            }
            
            if oauth2 {
                result = cmailsmtp_oauth2_authenticate(self.smtp, account, password)
            } else {
                result = cmailsmtp_login(self.smtp, account, password)
            }
            
            if let error = result.toSMTPString(self.smtpResponse()) {
                return returnCallback(error)
            }
            
            self.unsafeConnectionInfo = ConnectionInfo(domain: domain,
                                                       port: port,
                                                       account: account,
                                                       password: password,
                                                       oauth2: oauth2,
                                                       security: security)
            
            returnCallback(nil)
        }
    }
    
    /// Sends an already composed rfc822 message. from and recipients are the
    /// smtp envelope; they are not parsed out of the eml, so bcc recipients
    /// belong here and not in the headers.
    internal func _beSend(from: String,
                          recipients: [String],
                          eml: String,
                          _ returnCallback: @escaping (String?) -> ()) {
        guard recipients.isEmpty == false else {
            return returnCallback("no recipients provided")
        }
        
        // smtp requires CRLF line endings. libetpan terminates the DATA payload
        // with its own CRLF, so a trailing newline in the eml would arrive as
        // an extra blank line. work in bytes, not Characters, since "\r\n" is a
        // single Character in Swift
        var bytes = Array(eml
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "\r\n")
            .utf8)
        while bytes.count >= 2 && bytes[bytes.count - 2] == 0x0D && bytes[bytes.count - 1] == 0x0A {
            bytes.removeLast(2)
        }
        
        queue.addOperation {
            let cRecipients = recipients.map { strdup($0) }
            defer {
                for cRecipient in cRecipients {
                    free(cRecipient)
                }
            }
            
            var pointers = cRecipients.map { UnsafePointer<CChar>($0) }
            
            let result: CSMTPError = bytes.withUnsafeBufferPointer { buffer in
                return buffer.baseAddress!.withMemoryRebound(to: CChar.self, capacity: bytes.count) { emlPtr in
                    return cmailsmtp_send(self.smtp,
                                          from,
                                          Int32(recipients.count),
                                          &pointers,
                                          emlPtr,
                                          Int32(bytes.count))
                }
            }
            
            if let error = result.toSMTPString(self.smtpResponse()) {
                return returnCallback(error)
            }
            
            returnCallback(nil)
        }
    }
    
    /// Composes and sends an EML. The envelope is taken from the message; bcc
    /// recipients are included in the envelope but not in the headers.
    internal func _beSend(eml: EML,
                          _ returnCallback: @escaping (String?) -> ()) {
        _beSend(from: eml.from.email,
                recipients: eml.recipients,
                eml: eml.eml(),
                returnCallback)
    }
}

#endif
