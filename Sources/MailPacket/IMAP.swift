import Foundation
import Flynn
import Hitch
import libetpan
import Sextant

/*
 // Common error strings defined in mailcore 2 that libetpan can return
 ErrorGmailIMAPNotEnabled: "not enabled for IMAP use"
 ErrorGmailIMAPNotEnabled: "IMAP access is disabled"
 ErrorGmailExceededBandwidthLimit: "bandwidth limits"
 ErrorGmailTooManySimultaneousConnections: "Too many simultaneous connections"
 ErrorGmailTooManySimultaneousConnections: "Maximum number of connections"
 ErrorGmailApplicationSpecificPasswordRequired: "Application-specific password required"
 ErrorMobileMeMoved: "http://me.com/move"
 ErrorYahooUnavailable: "OCF12"
 ErrorOutlookLoginViaWebBrowser: "Login to your account via a web browser"
 ErrorConnection: "Service temporarily unavailable"
 */

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Header: Codable {
    public let messageID: Int
    public let headers: String
}

public struct Email: Codable {
    public let messageID: Int
    public let eml: String
}

public struct ConnectionInfo: Codable {
    public let domain: String
    public let port: Int
    public let account: String
    public let password: String
    public let oauth2: Bool
    
    public init(domain: String,
                port: Int,
                account: String,
                password: String,
                oauth2: Bool) {
        self.domain = domain
        self.port = port
        self.account = account
        self.password = password
        self.oauth2 = oauth2
    }
}

public class IMAP: Actor {
    private let queue: OperationQueue

    private let imap: UnsafeMutableRawPointer?
    
    public var unsafeConnectionInfo: ConnectionInfo?
    
    public override init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        imap = cmailimap_new()
    }
    
    deinit {
        cmailimap_free(imap)
    }
    
    private func imapResponse() -> String? {
        guard let cString = cimap_response(self.imap) else { return nil }
        let json = Hitch(own: cString)
        return json.toString()
    }
    
    internal func _beGetConnection() -> ConnectionInfo? {
        return unsafeConnectionInfo
    }
    
    internal func _beConnect(domain: String,
                             port: Int,
                             account: String,
                             password: String,
                             oauth2: Bool,
                             _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            var result: CError = cmailimap_ssl_connect(self.imap, domain, UInt16(port))
            if let error = result.toString(self.imapResponse()) {
                return returnCallback(error)
            }
            
            if oauth2 {
                result = cmailimap_oauth2_authenticate(self.imap, account, password);
            } else {
                result = cmailimap_login(self.imap, account, password)
            }
            
            if let error = result.toString(self.imapResponse()) {
                return returnCallback(error)
            }
            
            self.unsafeConnectionInfo = ConnectionInfo(domain: domain,
                                                       port: port,
                                                       account: account,
                                                       password: password,
                                                       oauth2: oauth2)
            
            result = cmailimap_select(self.imap, "INBOX")
            if let error = result.toString(self.imapResponse()) {
                return returnCallback(error)
            }
            
            returnCallback(nil)
        }
    }
    
    internal func _beSelect(folder: String,
                            _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            let result: CError = cmailimap_select(self.imap, folder)
            if let error = result.toString(self.imapResponse()) {
                return returnCallback(error)
            }
            
            returnCallback(nil)
        }
    }
    
    internal func _beSearch(folder: String,
                            after: Date,
                            smaller: Int = 0,
                            _ returnCallback: @escaping (String?, [Int]) -> ()) {
        queue.addOperation {
            let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: after)
            guard let day = calendarDate.day,
                  let month = calendarDate.month,
                  let year = calendarDate.year else {
                return returnCallback("failed to extract date components", [])
            }
            if let jsonUTF8 = cmailimap_search(self.imap,
                                               Int32(day),
                                               Int32(month),
                                               Int32(year),
                                               Int32(smaller)) {
                let json = Hitch(own: jsonUTF8)
                let messageIDs: [Int] = json.query("$[*]") ?? []
                return returnCallback(nil, messageIDs)
            }
            
            return returnCallback("unknown error", [])
        }
    }
    
    internal func _beHeaders(messageIDs: [Int],
                             _ returnCallback: @escaping (String?, [Header]) -> ()) {
        queue.addOperation {
            var cMessageIDs = messageIDs.map { Int32($0) }
            
            if let jsonUTF8 = cmailimap_headers(self.imap,
                                                Int32(messageIDs.count),
                                                &cMessageIDs) {
                let json = Hitch(own: jsonUTF8)
                let headers: [Header] = json.query("$[*]") ?? []
                return returnCallback(nil, headers)
            }
            
            return returnCallback("unknown error", [])
        }
    }
    
    internal func _beDownload(messageIDs: [Int],
                              _ returnCallback: @escaping (String?, [Email]) -> ()) {
        queue.addOperation {
            var cMessageIDs = messageIDs.map { Int32($0) }
            
            if let jsonUTF8 = cmailimap_download(self.imap,
                                                 Int32(messageIDs.count),
                                                 &cMessageIDs) {
                let json = Hitch(own: jsonUTF8)
                let emails: [Email] = json.query("$[*]") ?? []
                return returnCallback(nil, emails)
            }
            
            return returnCallback("unknown error", [])
        }
    }
}
