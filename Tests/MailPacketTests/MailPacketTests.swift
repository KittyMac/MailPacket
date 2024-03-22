import XCTest
import Hitch
import Flynn
import Studding

import MailPacket

fileprivate let account = try! String(contentsOfFile: "/Users/rjbowli/Development/data/passwords/imap_username.txt")
fileprivate let password = try! String(contentsOfFile: "/Users/rjbowli/Development/data/passwords/imap_password.txt")

final class MailPacketTests: XCTestCase {
    func testIMAPSearch0() {
        let expectation = XCTestExpectation(description: #function)

        let imap = IMAP()
        
        imap.beConnect(domain: "imap.gmail.com",
                       port: 993,
                       account: account,
                       password: password,
                       oauth2: false,
                       imap) { error in
            
            XCTAssertNil(error)
            
            imap.beGetFolders(imap) { folders in
                
                print(folders)
                
                imap.beSearch(folder: "[Gmail]/All Mail",
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
                            
                            expectation.fulfill()
                        }
                    }
                    
                }
            }
            
            
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    // ya29.a0AfB_byCErIjUYTOWB8XhvAKWfdJghC4hKV8SQBb4EHkyHrczB5P0kbP5Dl3D3Le_MtXPofjDHFqtWJ9iT68nu1hBseSkh1Y4vqOWTFmkl3WqnkubecVfGR3JyvRU-IGWNI92yf2NBaZxNJwfcyAxpxEuz7c0dmH2Y7pAaCgYKAVoSARISFQHGX2Mipwf2noeoAhGmKRYJaV1UWw0171
    func testOAuthSearch0() {
        let expectation = XCTestExpectation(description: #function)

        let imap = IMAP()
        
        // https://developers.google.com/oauthplayground
        let accessToken = "ya29.a0AfB_byCErIjUYTOWB8XhvAKWfdJghC4hKV8SQBb4EHkyHrczB5P0kbP5Dl3D3Le_MtXPofjDHFqtWJ9iT68nu1hBseSkh1Y4vqOWTFmkl3WqnkubecVfGR3JyvRU-IGWNI92yf2NBaZxNJwfcyAxpxEuz7c0dmH2Y7pAaCgYKAVoSARISFQHGX2Mipwf2noeoAhGmKRYJaV1UWw0171"
        
        imap.beConnect(domain: "imap.gmail.com",
                       port: 993,
                       account: "test@gmail.com",
                       password: accessToken,
                       oauth2: true,
                       imap) { error in
            
            XCTAssertNil(error)
            
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
                        
                        expectation.fulfill()
                    }
                }
                
            }
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
