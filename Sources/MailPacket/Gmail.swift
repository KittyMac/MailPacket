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
 {
   "access_token": "...",
   "expires_in": 3599,
   "scope": "https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/userinfo.profile openid",
   "token_type": "Bearer",
   "id_token": "..."
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

typealias TokenRefreshCallback = (String?) -> ()
typealias DownloaderCallback = (HTTPSession, @escaping () -> ()) -> ()

class GmailDownloader: Actor {
    private var lastPerformDate = Date.distantPast
    private var speedLimit: Double

    var unsafeIsSpeedLimited: Bool {
        let timeSpentSoFar = abs(lastPerformDate.timeIntervalSinceNow)
        return timeSpentSoFar < speedLimit
    }
    
    init(speedLimit: Double) {
        self.speedLimit = speedLimit
    }
    
    internal func _bePerform(_ performBlock: @escaping DownloaderCallback,
                             _ returnCallback: @escaping () -> ()) {
        HTTPSessionManager.shared.beNew(priority: .high,
                                        self) { session in
            self.lastPerformDate = Date()
            performBlock(session, returnCallback)
        }
    }
}


public class Gmail: Actor {
    public struct Header: Codable {
        public let messageID: String
        public let headers: String
    }

    public struct Email: Codable {
        public let messageID: String
        public let eml: String
    }
    
    public struct TokenRefresh: Codable {
        public let clientId: String
        public let clientSecret: String
        public let refreshToken: String
        
        public init(clientId: String,
                    clientSecret: String,
                    refreshToken: String) {
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.refreshToken = refreshToken
        }
    }

    public struct ConnectionInfo: Codable {
        public let accessToken: String
        public let concurrency: Int
        public let speedLimit: Double
        public let tokenRefresh: TokenRefresh?
        
        public init(accessToken: String,
                    concurrency: Int,
                    speedLimit: Double,
                    tokenRefresh: TokenRefresh?) {
            self.accessToken = accessToken
            self.concurrency = concurrency
            self.speedLimit = speedLimit
            self.tokenRefresh = tokenRefresh
        }
    }
    
    public var unsafeConnectionInfo: ConnectionInfo?
    
    private var accessToken: String = ""
    private var tokenRefresh: TokenRefresh?
    private var tokenExpiry: Date = Date.distantFuture
    
    private var activeDownloaders: [GmailDownloader] = []
    private var freeDownloaders: [GmailDownloader] = []
    private var requestQueue: [DownloaderCallback] = []
    
    public override init() {
        super.init()
        
        Flynn.Timer(timeInterval: 0.01, immediate: false, repeats: true, self) { [weak self] timer in
            self?.nextRequest()
        }
    }
    
    private func refreshToken(_ callback: @escaping TokenRefreshCallback) {
        guard let tokenRefresh = tokenRefresh else { return callback(nil) }
        guard abs(tokenExpiry.timeIntervalSinceNow) < 60 * 5 else { return callback(nil) }
        
        HTTPSession.oneshot.beRequest(url: "https://oauth2.googleapis.com/token",
                                      httpMethod: "POST",
                                      params: [
                                        "client_id": tokenRefresh.clientId,
                                        "client_secret": tokenRefresh.clientSecret,
                                        "refresh_token": tokenRefresh.refreshToken,
                                        "grant_type": "refresh_token",
                                      ],
                                      headers: [
                                        "Content-Type": "application/x-www-form-urlencoded"
                                      ],
                                      cookies: nil,
                                      timeoutRetry: nil,
                                      proxy: nil,
                                      body: nil,
                                      self) { response, httpResponse, error in
            if let error = error {
                return callback(error)
            }
            guard let response = response else {
                return callback(error ?? "Unknown error")
            }
            

            let json = Hitch(data: response)
            guard let newAccessToken: String = json.query("$.access_token") else { return callback("token refresh missing access_token") }
            guard let expiresIn: Double = json.query("$.expires_in") else { return callback("token refresh missing expires_in") }

            self.accessToken = newAccessToken
            self.tokenExpiry = Date(timeIntervalSinceNow: expiresIn)
            
            callback(nil)
        }
    }
    
    private func scheduleRequest(_ callback: @escaping DownloaderCallback) {
        requestQueue.append(callback)
        nextRequest()
    }
    
    private func nextRequest() {
        // print("requests: \(requestQueue.count)  free: \(freeDownloaders.count)   active: \(activeDownloaders.count)")
        
        guard requestQueue.isEmpty == false else { return }
        guard freeDownloaders.isEmpty == false else { return }
        guard freeDownloaders[0].unsafeIsSpeedLimited == false else {
            return
        }
        
        let downloader = freeDownloaders.removeFirst()
        let request = requestQueue.removeFirst()
        
        refreshToken { error in
            downloader.bePerform(request,
                                 self) {
                self.activeDownloaders = self.activeDownloaders.filter { $0 != downloader }
                self.freeDownloaders.append(downloader)
                
                self.nextRequest()
            }
            self.activeDownloaders.append(downloader)
        }
    }
    
    internal func _beClose(_ returnCallback: @escaping () -> ()) {
        // TODO: stub for completeness
        returnCallback()
    }
    
    internal func _beGetConnection() -> ConnectionInfo? {
        return unsafeConnectionInfo
    }
    
    internal func _beConnect(oauth2 accessToken: String,
                             tokenRefresh: TokenRefresh?,
                             concurrency: Int,
                             speedLimit: Double,
                             _ returnCallback: @escaping (String?) -> ()) {
        self.accessToken = accessToken
        self.tokenRefresh = tokenRefresh
        self.tokenExpiry = Date()
        
        for _ in 0..<concurrency {
            freeDownloaders.append(
                GmailDownloader(speedLimit: speedLimit)
            )
        }
        
        scheduleRequest { session, finishedCallback in
            session.beRequest(url: "https://gmail.googleapis.com/gmail/v1/users/me/profile",
                              httpMethod: "GET",
                              params: [:],
                              headers: [
                                "Authorization": "Bearer \(self.accessToken)"
                              ],
                              cookies: nil,
                              timeoutRetry: nil,
                              proxy: nil,
                              body: nil,
                              self) { response, httpResponse, error in
                defer { finishedCallback() }
                
                if let error = error {
                    return returnCallback(error)
                }
                guard let _ = response else {
                    return returnCallback(error ?? "Unknown error")
                }
                
                self.unsafeConnectionInfo = ConnectionInfo(accessToken: accessToken,
                                                           concurrency: concurrency,
                                                           speedLimit: speedLimit,
                                                           tokenRefresh: tokenRefresh)
                
                returnCallback(nil)
            }
        }
    }
    
    internal func _beSearch(after: Date,
                            smaller: Int = 0,
                            _ returnCallback: @escaping (String?, [String]) -> ()) {
        performSearch(after: after,
                      smaller: smaller,
                      nextPageToken: nil,
                      results: [],
                      returnCallback)
    }
    
    private func performSearch(after: Date,
                               smaller: Int,
                               nextPageToken: String?,
                               results: Set<String>,
                               _ returnCallback: @escaping (String?, [String]) -> ()) {
        
        scheduleRequest { session, finishedCallback in
            var params = [
                "maxResults": "500",
            ]
            if let nextPageToken = nextPageToken {
                params["pageToken"] = nextPageToken
            } else {
                params["q"] = "in:anywhere -in:drafts smaller_than:\(smaller / 1024)KB after:\(Int(after.timeIntervalSince1970))"
            }
            session.beRequest(url: "https://www.googleapis.com/gmail/v1/users/me/messages",
                              httpMethod: "GET",
                              params: params,
                              headers: [
                                "Authorization": "Bearer \(self.accessToken)"
                              ],
                              cookies: nil,
                              timeoutRetry: nil,
                              proxy: nil,
                              body: nil,
                              self) { response, httpResponse, error in
                defer { finishedCallback() }
                
                if let error = error {
                    return returnCallback(error, [])
                }
                guard let response = response else {
                    return returnCallback(error ?? "Unknown error", [])
                }
                
                let json = Hitch(data: response)
                let messageIDs: [String] = json.query("$.messages[*].id") ?? []
                
                var localResults = results
                for messageID in messageIDs {
                    localResults.insert(messageID)
                }
                
                guard localResults.count == results.count + messageIDs.count else {
                    return returnCallback("duplicate messageIds returned", messageIDs)
                }
                
                if let nextPageToken: String = json.query("$.nextPageToken") {
                    return self.performSearch(after: after,
                                              smaller: smaller,
                                              nextPageToken: nextPageToken,
                                              results: localResults,
                                              returnCallback)
                    
                }
                
                return returnCallback(nil, Array(localResults))
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
            scheduleRequest { session, finishedCallback in
                session.beRequest(url: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageID)",
                                  httpMethod: "GET",
                                  params: [
                                    "format": "metadata"
                                  ],
                                  headers: [
                                    "Authorization": "Bearer \(self.accessToken)"
                                  ],
                                  cookies: nil,
                                  timeoutRetry: nil,
                                  proxy: nil,
                                  body: nil,
                                  self) { response, httpResponse, error in
                    defer { finishedCallback(); group.leave() }
                    
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
                    
                    let header = Hitch(capacity: 1024)
                    for (key, value) in headers {
                        header.append(key)
                        header.append(.colon)
                        header.append(.space)
                        header.append(value)
                        header.append(.newLine)
                    }
                    header.append(.newLine)
                    
                    allHeaders.append(
                        Header(messageID: messageID,
                               headers: header.toString())
                    )
                }
            }
        }
        
        group.notify(actor: self) {
            return returnCallback(anyError, allHeaders)
        }
    }
    
    internal func _beDownload(messageIDs: [String],
                              _ returnCallback: @escaping (String?, [Email]) -> ()) {
        let group = DispatchGroup()
        var anyError: String? = nil
        var allEmails: [Email] = []
        
        for messageID in messageIDs {
            
            group.enter()
            scheduleRequest { session, finishedCallback in
                session.beRequest(url: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageID)",
                                  httpMethod: "GET",
                                  params: [
                                    "format": "raw"
                                  ],
                                  headers: [
                                    "Authorization": "Bearer \(self.accessToken)"
                                  ],
                                  cookies: nil,
                                  timeoutRetry: nil,
                                  proxy: nil,
                                  body: nil,
                                  self) { response, httpResponse, error in
                    defer { finishedCallback(); group.leave() }
                    
                    if let error = error, anyError == nil {
                        anyError = error
                        return
                    }
                    guard let response = response else {
                        anyError = "empty response without error"
                        return
                    }
                    
                    // defaultPerMinutePerUser: 15000
                    // 250 quota units per user per second, moving average (allows short bursts).
                    
                    let json = Hitch(data: response)
                    guard let base64UrlEncoded = json.query(hitch: "$..raw") else {
                        anyError = "raw is missing from response"
                        return
                    }
                    
                    base64UrlEncoded.replace(occurencesOf: "-", with: "+")
                    base64UrlEncoded.replace(occurencesOf: "_", with: "/")
                    
                    guard let data = base64UrlEncoded.base64Decoded() else {
                        anyError = "failed decode raw"
                        return
                    }
                    
                    allEmails.append(
                        Email(messageID: messageID,
                              eml: Hitch(data: data).toString())
                    )
                }
            }
        }
        
        group.notify(actor: self) {
            return returnCallback(anyError, allEmails)
        }
    }
}
