import Foundation
import Flynn
import Hitch
import libetpan
import Sextant
import Picaroon

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class Gmail: Actor {
    public struct ConnectionInfo: Codable {
        public let oauth2: String
        
        public init(oauth2: String) {
            self.oauth2 = oauth2
        }
    }
    
    private var token: String = ""
    
    internal func _beConnect(oauth2: String,
                             _ returnCallback: @escaping (String?) -> ()) {
        token = oauth2
        
        HTTPSessionManager.shared.beNew(priority: .high,
                                        self) { session in
            
            session.beRequest(url: "https://www.googleapis.com/gmail/v1/users/me/messages",
                              httpMethod: "GET",
                              params: [:],
                              headers: [
                                "Authorization": "Bearer \(self.token)"
                              ],
                              cookies: nil,
                              timeoutRetry: nil,
                              proxy: nil,
                              body: nil,
                              self) { response, httpResponse, error in
                guard let response = response else {
                    return returnCallback(error ?? "Unknown error")
                }
                
                print(Hitch(data: response))
            }
            
        }
        
    }
}
