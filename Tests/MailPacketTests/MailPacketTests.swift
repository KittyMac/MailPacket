import XCTest
import Hitch
import Flynn
import Spanker

import MailPacket

fileprivate let imapAccount = try! String(contentsOfFile: "/Users/rjbowli/Development/data/passwords/gmail_imap_username.txt")
fileprivate let imapPassword = try! String(contentsOfFile: "/Users/rjbowli/Development/data/passwords/gmail_imap_password.txt")

fileprivate let gmailAccount = Spanker.parse(halfhitch: Hitch(contentsOfFile: "/Users/rjbowli/Development/data/passwords/gmail_oauth2.json")!.halfhitch())!

final class MailPacketTests: XCTestCase {
    func testIMAP0() {
        let expectation = XCTestExpectation(description: #function)

        let imap = IMAP()
        
        imap.beConnect(domain: "imap.gmail.com",
                       port: 993,
                       account: imapAccount,
                       password: imapPassword,
                       oauth2: false,
                       imap) { error in
            
            XCTAssertNil(error)
            
            imap.beGetFolders(imap) { folders in
                
                print(folders)
                
                imap.beExamine(folder: "[Gmail]/All Mail",
                               imap) { error in
                    
                    imap.beSearch(folder: "INBOX",
                                  after: "2/26/2024".date()!,
                                  smaller: 1024 * 512,
                                  imap) { error, messageIds in
                        XCTAssertNil(error)
                                        
                        print(messageIds)
                        
                        imap.beHeaders(messageIDs: messageIds, imap) { error, headers in
                            XCTAssertNil(error)
                            XCTAssertEqual(messageIds.count, headers.count)
                            
                            for header in headers {
                                print("\(header.messageID): \(header.headers.count) header bytes")
                                //try? header.headers.write(toFile: "/tmp/header\(header.messageID).txt", atomically: false, encoding: .utf8)
                            }
                            
                            imap.beDownload(messageIDs: messageIds, imap) { error, emails in
                                XCTAssertNil(error)
                                XCTAssertEqual(messageIds.count, emails.count)
                                
                                for email in emails {
                                    print("\(email.messageID): \(email.eml.count) eml bytes")
                                    
                                    try? email.eml.write(toFile: "/tmp/email_\(email.messageID).eml", atomically: false, encoding: .utf8)
                                }
                                
                                imap.beClose(imap) {
                                    expectation.fulfill()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 60)
    }
    
    func testGmail0() {
        let expectation = XCTestExpectation(description: #function)

        let gmail = Gmail()
        
        let accessToken = gmailAccount[string: "accessToken"]!
        let refreshToken = gmailAccount[string: "refreshToken"]!
        let clientId = gmailAccount[string: "clientId"]!
        let clientSecret = gmailAccount[string: "clientSecret"]!
        
        let tokenRefresh = Gmail.TokenRefresh(clientId: clientId,
                                              clientSecret: clientSecret,
                                              refreshToken: refreshToken)
        
        // Requires OAUTH2 token with appropriate scopes.
        // "https://www.googleapis.com/auth/gmail.readonly" is good scope to start with
        // Set up app on google: https://console.cloud.google.com
        // Use something like https://github.com/openid/AppAuth-iOS to sign in and get an access token
        gmail.beConnect(oauth2: accessToken,
                        tokenRefresh: tokenRefresh,
                        concurrency: 16,
                        speedLimit: 0.6,
                        gmail)  { error in
            XCTAssertNil(error)

            gmail.beSearch(after: "1/1/2019".date()!,
                           smaller: 1024 * 512,
                           gmail) { error, messageIds in
                XCTAssertNil(error)
                
                print(messageIds)
                
                gmail.beHeaders(messageIDs: messageIds, gmail) { error, headers in
                    XCTAssertNil(error)
                    XCTAssertEqual(messageIds.count, headers.count)
                    
                    gmail.beDownload(messageIDs: messageIds, gmail) { error, emails in
                        XCTAssertNil(error)
                        XCTAssertEqual(messageIds.count, emails.count)
                        
                        for email in emails {
                            print("\(email.messageID): \(email.eml.count) eml bytes")
                            
                            try? email.eml.write(toFile: "/tmp/email_\(email.messageID).eml", atomically: false, encoding: .utf8)
                        }
                        
                        gmail.beClose(gmail) {
                            expectation.fulfill()
                        }
                    }
                    
                }
            }
        }
        
        wait(for: [expectation], timeout: 240)
    }
}
