import Foundation
import Flynn
import Hitch
import libetpan
import Sextant

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Header: Codable {
    public let messageID: Int
    public let headers: String
    public let env_date: String
    public let env_subject: String
    public let summary: String
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
    
    public init(domain: String,
                port: Int,
                account: String,
                password: String) {
        self.domain = domain
        self.port = port
        self.account = account
        self.password = password
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
    
    internal func _beGetConnection() -> ConnectionInfo? {
        return unsafeConnectionInfo
    }
    
    internal func _beConnect(domain: String,
                             port: Int,
                             account: String,
                             password: String,
                             _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            var result: CError = cmailimap_ssl_connect(self.imap, domain, UInt16(port))
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            result = cmailimap_login(self.imap, account, password)
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            self.unsafeConnectionInfo = ConnectionInfo(domain: domain,
                                                       port: port,
                                                       account: account,
                                                       password: password)
            
            result = cmailimap_select(self.imap, "INBOX")
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            returnCallback(nil)
        }
    }
    
    internal func _beSelect(folder: String,
                            _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            let result: CError = cmailimap_select(self.imap, folder)
            if let error = result.toString() {
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
