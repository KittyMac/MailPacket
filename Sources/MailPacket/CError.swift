import Foundation
import Flynn
import Hitch

#if canImport(libetpan)
import libetpan

typealias CError = Int32

extension CError {
    private enum CErrorEnum: Int32 {
        case success = 0
        case success_authenticated = 1
        case success_non_authenticated = 2
        case bad_state
        case stream
        case parse
        case connection_refused
        case memory
        case fatal
        case `protocol`
        case dont_accept_connection
        case append
        case noop
        case logout
        case capability
        case check
        case close
        case expunge
        case copy
        case uid_copy
        case move
        case uid_move
        case create
        case delete
        case examine
        case fetch
        case uid_fetch
        case list
        case login
        case lsub
        case rename
        case search
        case uid_search
        case select
        case status
        case store
        case uid_store
        case subscribe
        case unsubscribe
        case starttls
        case inval
        case `extension`
        case sasl
        case ssl
        case needs_more_data
        case custom_command
        case clientid
    }
    
    func toString(_ detials: String?) -> String? {
        switch CErrorEnum(rawValue: self) {
        case .success: return nil
        case .success_authenticated: return nil
        case .success_non_authenticated: return nil
        case .bad_state: return "bad_state: \(detials ?? "unknown")"
        case .stream: return "stream: \(detials ?? "unknown")"
        case .parse: return "parse: \(detials ?? "unknown")"
        case .connection_refused: return "connection_refused: \(detials ?? "unknown")"
        case .memory: return "memory: \(detials ?? "unknown")"
        case .fatal: return "fatal: \(detials ?? "unknown")"
        case .protocol: return "protocol: \(detials ?? "unknown")"
        case .dont_accept_connection: return "dont_accept_connection: \(detials ?? "unknown")"
        case .append: return "append: \(detials ?? "unknown")"
        case .noop: return "noop: \(detials ?? "unknown")"
        case .logout: return "logout: \(detials ?? "unknown")"
        case .capability: return "capability: \(detials ?? "unknown")"
        case .check: return "check: \(detials ?? "unknown")"
        case .close: return "close: \(detials ?? "unknown")"
        case .expunge: return "expunge: \(detials ?? "unknown")"
        case .copy: return "copy: \(detials ?? "unknown")"
        case .uid_copy: return "uid_copy: \(detials ?? "unknown")"
        case .move: return "move: \(detials ?? "unknown")"
        case .uid_move: return "uid_move: \(detials ?? "unknown")"
        case .create: return "create: \(detials ?? "unknown")"
        case .delete: return "delete: \(detials ?? "unknown")"
        case .examine: return "examine: \(detials ?? "unknown")"
        case .fetch: return "fetch: \(detials ?? "unknown")"
        case .uid_fetch: return "uid_fetch: \(detials ?? "unknown")"
        case .list: return "list: \(detials ?? "unknown")"
        case .login: return "login: \(detials ?? "unknown")"
        case .lsub: return "lsub: \(detials ?? "unknown")"
        case .rename: return "rename: \(detials ?? "unknown")"
        case .search: return "search: \(detials ?? "unknown")"
        case .uid_search: return "uid_search: \(detials ?? "unknown")"
        case .select: return "select: \(detials ?? "unknown")"
        case .status: return "status: \(detials ?? "unknown")"
        case .store: return "store: \(detials ?? "unknown")"
        case .uid_store: return "uid_store: \(detials ?? "unknown")"
        case .subscribe: return "subscribe: \(detials ?? "unknown")"
        case .unsubscribe: return "unsubscribe: \(detials ?? "unknown")"
        case .starttls: return "starttls: \(detials ?? "unknown")"
        case .inval: return "inval: \(detials ?? "unknown")"
        case .extension: return "extension: \(detials ?? "unknown")"
        case .sasl: return "sasl: \(detials ?? "unknown")"
        case .ssl: return "ssl: \(detials ?? "unknown")"
        case .needs_more_data: return "needs_more_data: \(detials ?? "unknown")"
        case .custom_command: return "custom_command: \(detials ?? "unknown")"
        case .clientid: return "clientid: \(detials ?? "unknown")"
        default: return "unknown error: \(detials ?? "unknown")"
        }
    }
}

#endif