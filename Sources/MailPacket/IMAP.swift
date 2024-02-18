import Foundation
import Flynn
import Hitch
import libetpan

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class IMAP: Actor {
    private let queue: OperationQueue
    
    private let imap: UnsafeMutableRawPointer?
    private let domain: String
    private let port: Int
    
    public init(domain: String,
                port: Int) {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        imap = cmailimap_new()
        self.domain = domain
        self.port = port
    }
    
    internal func _beConnect(account: String,
                             password: String,
                             _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            var result: CError = cmailimap_ssl_connect(self.imap, "imap.gmail.com", 993)
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            result = cmailimap_login(self.imap, account, password)
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            returnCallback(nil)
        }
    }
    
    internal func _beSelect(folder: String,
                            _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            let result: CError = cmailimap_select(self.imap, "INBOX")
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            returnCallback(nil)
        }
    }
    
    internal func _beSearch(folder: String,
                            after: Date,
                            _ returnCallback: @escaping (String?) -> ()) {
        queue.addOperation {
            var result: CError = cmailimap_select(self.imap, "INBOX")
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: after)
            guard let day = calendarDate.day,
                  let month = calendarDate.month,
                  let year = calendarDate.year else {
                return returnCallback("failed to extract date components")
            }
            result = cmailimap_uid_search(self.imap, Int32(day), Int32(month), Int32(year))
            if let error = result.toString() {
                return returnCallback(error)
            }
            
            returnCallback(nil)
        }
    }
}
