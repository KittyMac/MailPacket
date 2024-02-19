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

        let imap = IMAP(domain: "imap.gmail.com",
                        port: 993)
        
        imap.beConnect(account: account,
                       password: password,
                       imap) { error in
            
            XCTAssertNil(error)
            
            imap.beSearch(folder: "INBOX",
                          after: Date(timeIntervalSinceNow: 60 * 60 * 24 * 30 * -1),
                          smaller: 1024 * 512,
                          imap) { error, messageIds in
                XCTAssertNil(error)
                                
                print(messageIds)
                
                imap.beHeaders(messageIDs: messageIds, imap) { error, headers in
                    XCTAssertNil(error)
                    XCTAssertEqual(messageIds.count, headers.count)
                    
                    for header in headers {
                        print("\(header.messageID): \(header.headers.count) bytes")
                    }
                    
                    expectation.fulfill()
                }
                
            }
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
}
