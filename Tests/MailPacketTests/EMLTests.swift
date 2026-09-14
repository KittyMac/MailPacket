import XCTest
import Flynn
import MailPacket

final class EMLTests: XCTestCase {

    private let utc = TimeZone(identifier: "UTC")!
    private let fixedDate = Date(timeIntervalSince1970: 1704110400) // 2024-01-01 12:00:00 UTC

    func testSimpleAscii() {
        let message = EML(from: EML.Address("alice@example.com", name: "Alice"),
                          to: [EML.Address("bob@example.com", name: "Bob")],
                          subject: "hello there",
                          body: "just a plain text body\n",
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<fixed@example.com>",
                          userAgent: nil)
        let eml = message.eml()

        let expected = "Date: Mon, 01 Jan 2024 12:00:00 +0000\r\n" +
                       "From: Alice <alice@example.com>\r\n" +
                       "To: Bob <bob@example.com>\r\n" +
                       "Subject: hello there\r\n" +
                       "Message-ID: <fixed@example.com>\r\n" +
                       "MIME-Version: 1.0\r\n" +
                       "Content-Type: text/plain; charset=us-ascii\r\n" +
                       "Content-Transfer-Encoding: 7bit\r\n" +
                       "\r\n" +
                       "just a plain text body\r\n"
        XCTAssertEqual(eml, expected)
    }

    func testGeneratedMessageID() {
        let message = EML(from: EML.Address("alice@example.com"),
                          to: [EML.Address("bob@example.com")],
                          subject: "x",
                          body: "y")
        XCTAssertTrue(message.messageID.hasPrefix("<"))
        XCTAssertTrue(message.messageID.hasSuffix("@example.com>"))
        // stable across calls
        XCTAssertEqual(message.messageID, message.messageID)
        XCTAssertTrue(message.eml().contains("Message-ID: \(message.messageID)"))
    }

    func testUnicode() {
        let message = EML(from: EML.Address("alice@example.com", name: "Álice Ñoño"),
                          to: [EML.Address("bob@example.com", name: "Bob")],
                          subject: "unicode ☕ subject with a fairly long tail so it has to wrap somewhere sensible",
                          body: "unicode body: 👋 héllo\n",
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<unicode@example.com>")
        let eml = message.eml()

        XCTAssertTrue(eml.contains("=?utf-8?B?"))
        XCTAssertTrue(eml.contains("Content-Transfer-Encoding: base64"))
        XCTAssertTrue(eml.contains("charset=utf-8"))
        XCTAssertFalse(eml.contains("👋"), "body should be base64 encoded")
    }

    func testHeaderInjection() {
        let message = EML(from: EML.Address("alice@example.com", name: "Alice\r\nX-Evil: yes"),
                          to: [EML.Address("bob@example.com")],
                          subject: "hello\r\nBcc: evil@example.com\r\n",
                          body: "body\n",
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<injection@example.com>",
                          extraHeaders: [EML.Header("X-Custom", "value\r\nX-Also-Evil: yes")])
        let eml = message.eml()

        // the injected text survives as header *content*, but must not start
        // a new header line: every line after the first is either a new
        // "Name: value" or a folded continuation beginning with whitespace
        let headers = eml.components(separatedBy: "\r\n\r\n").first ?? ""
        for line in headers.components(separatedBy: "\r\n") {
            guard line.hasPrefix(" ") == false && line.hasPrefix("\t") == false else { continue }
            let name = line.components(separatedBy: ":").first ?? ""
            XCTAssertTrue(["Date", "From", "To", "Subject", "Message-ID", "User-Agent",
                           "X-Custom", "MIME-Version", "Content-Type",
                           "Content-Transfer-Encoding"].contains(name),
                          "unexpected header line: \(line)")
        }
    }

    func testBccNotInHeaders() {
        let message = EML(from: EML.Address("alice@example.com"),
                          to: [EML.Address("bob@example.com")],
                          subject: "bcc test",
                          body: "body\n",
                          cc: [EML.Address("carol@example.com")],
                          bcc: [EML.Address("dave@example.com")],
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<bcc@example.com>")
        let eml = message.eml()

        XCTAssertTrue(eml.contains("Cc: carol@example.com"))
        XCTAssertFalse(eml.contains("dave@example.com"))
        XCTAssertEqual(message.recipients, ["bob@example.com", "carol@example.com", "dave@example.com"])
    }

    func testLongLineForcesBase64() {
        let message = EML(from: EML.Address("alice@example.com"),
                          to: [EML.Address("bob@example.com")],
                          subject: "long line",
                          body: String(repeating: "a", count: 1200) + "\n",
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<longline@example.com>")
        let eml = message.eml()

        XCTAssertTrue(eml.contains("Content-Transfer-Encoding: base64"))
        for line in eml.components(separatedBy: "\r\n") {
            XCTAssertLessThanOrEqual(line.utf8.count, 998)
        }
    }

    func testManyRecipientsFold() {
        let recipients = (0..<20).map { EML.Address("recipient\($0)@example.com", name: "Recipient \($0)") }
        let message = EML(from: EML.Address("alice@example.com"),
                          to: recipients,
                          subject: "fold test",
                          body: "body\n",
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<fold@example.com>")
        let eml = message.eml()

        for line in eml.components(separatedBy: "\r\n") {
            XCTAssertLessThanOrEqual(line.utf8.count, 998)
        }
    }

    func testThreading() {
        let message = EML(from: EML.Address("alice@example.com"),
                          to: [EML.Address("bob@example.com")],
                          subject: "Re: original",
                          body: "reply body\n",
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<reply@example.com>",
                          inReplyTo: "<original@example.com>",
                          references: ["<first@example.com>", "<original@example.com>"])
        let eml = message.eml()

        XCTAssertTrue(eml.contains("In-Reply-To: <original@example.com>"))
        XCTAssertTrue(eml.contains("References: <first@example.com> <original@example.com>"))
    }

    func testQuotedDisplayName() {
        let message = EML(from: EML.Address("alice@example.com", name: "Alice, The Great"),
                          to: [EML.Address("bob@example.com", name: "Bob \"Bobby\" Jones")],
                          subject: "quoting",
                          body: "body\n",
                          date: fixedDate,
                          timeZone: utc,
                          messageID: "<quoting@example.com>")
        let eml = message.eml()

        XCTAssertTrue(eml.contains("\"Alice, The Great\" <alice@example.com>"))
        XCTAssertTrue(eml.contains("\\\"Bobby\\\""))
    }
}
