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
}
