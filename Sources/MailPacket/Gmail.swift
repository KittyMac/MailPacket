import Foundation
import Flynn
import Hitch
import libetpan
import Sextant
import Picaroon
import Spanker

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/*
 {
   "error": {
     "code": 401,
     "message": "Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
     "errors": [
       {
         "message": "Invalid Credentials",
         "domain": "global",
         "reason": "authError",
         "location": "Authorization",
         "locationType": "header"
       }
     ],
     "status": "UNAUTHENTICATED"
   }
 }
 */

/*
 // https://gmail.googleapis.com/gmail/v1/users/me/profile
 {
   "emailAddress": "email@gmail.com",
   "messagesTotal": 2124,
   "threadsTotal": 1727,
   "historyId": "210152"
 }
 */

// https://developers.google.com/gmail/api/reference/rest/v1/users.messages/list
// https://www.googleapis.com/gmail/v1/users/me/messages
/*
 {
   "messages": [
     {
       "id": "18e7c8b0b8fa42d1",
       "threadId": "18e7c8b0b8fa42d1"
     },
     {
       "id": "18e78dc7243b55fa",
       "threadId": "18e78dc7243b55fa"
     }
   ],
   "nextPageToken": "11922046136234252634",
   "resultSizeEstimate": 201
 }
 */
 

// https://gmail.googleapis.com/gmail/v1/users/me/messages/
// format=minimal
/*
 {
   "id": "18e5f8882a5de753",
   "threadId": "18e5f8882a5de753",
   "labelIds": [
     "UNREAD",
     "CATEGORY_UPDATES",
     "INBOX"
   ],
   "snippet": "Get started with FigJam templates for meetings, brainstorms, and more. \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c \u200c",
   "payload": {
     "mimeType": "multipart/alternative"
   },
   "sizeEstimate": 51705,
   "historyId": "209674",
   "internalDate": "1710998358000"
 }
 */



public class Gmail: Actor {
    public struct Header: Codable {
        public let messageID: String
        public let headers: [String: String]
    }

    public struct Email: Codable {
        public let messageID: String
        public let eml: String
    }

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
            
            session.beRequest(url: "https://gmail.googleapis.com/gmail/v1/users/me/profile",
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
                if let error = error {
                    return returnCallback(error)
                }
                guard let response = response else {
                    return returnCallback(error ?? "Unknown error")
                }
                returnCallback(nil)
            }
        }
    }
    
    internal func _beSearch(after: Date,
                            smaller: Int = 0,
                            _ returnCallback: @escaping (String?, [String]) -> ()) {
        
        HTTPSessionManager.shared.beNew(priority: .high,
                                        self) { session in
            
            session.beRequest(url: "https://www.googleapis.com/gmail/v1/users/me/messages",
                              httpMethod: "GET",
                              params: [
                                "maxResults": "500",
                                "q": "in:anywhere -in:drafts smaller_than:\(smaller / 1024)KB after:\(Int(after.timeIntervalSince1970))"
                              ],
                              headers: [
                                "Authorization": "Bearer \(self.token)"
                              ],
                              cookies: nil,
                              timeoutRetry: nil,
                              proxy: nil,
                              body: nil,
                              self) { response, httpResponse, error in
                if let error = error {
                    return returnCallback(error, [])
                }
                guard let response = response else {
                    return returnCallback(error ?? "Unknown error", [])
                }
                
                let json = Hitch(data: response)
                let messageIDs: [String] = json.query("$.messages[*].id") ?? []
                return returnCallback(nil, messageIDs)
            }
        }
    }
    
    internal func _beHeaders(messageIDs: [String],
                             _ returnCallback: @escaping (String?, [Header]) -> ()) {
        
        let group = DispatchGroup()
        var anyError: String? = nil
        var allHeaders: [Header] = []
        
        for messageID in messageIDs {
            
            group.enter()
            HTTPSessionManager.shared.beNew(priority: .high,
                                            self) { session in
                session.beRequest(url: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageID)",
                                  httpMethod: "GET",
                                  params: [
                                    "format": "metadata"
                                  ],
                                  headers: [
                                    "Authorization": "Bearer \(self.token)"
                                  ],
                                  cookies: nil,
                                  timeoutRetry: nil,
                                  proxy: nil,
                                  body: nil,
                                  self) { response, httpResponse, error in
                    defer { group.leave() }
                    
                    if let error = error, anyError == nil {
                        anyError = error
                    }
                    guard let response = response else {
                        anyError = "empty response without error"
                        return
                    }
                    
                    let json = Hitch(data: response)
                    var headers: [String: String] = [:]
                    
                    Spanker.parsed(hitch: json) { root in
                        guard let root = root else { return }
                        json.query(forEach: "$..headers[*]") { item in
                            guard let name = item[string: "name"] else { return }
                            guard let value = item[string: "value"] else { return }
                            headers[name] = value
                        }
                        if let snippet: String = root.query("$..snippet") {
                            headers["snippet"] = snippet
                        }
                    }
                    
                    allHeaders.append(
                        Header(messageID: messageID,
                               headers: headers)
                    )
                }
            }
        }
        
        group.notify(actor: self) {
            return returnCallback(anyError, allHeaders)
        }
    }
}
