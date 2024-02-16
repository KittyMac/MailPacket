import Foundation
import Flynn
import Hitch
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
    
    func toString() -> String? {
        switch CErrorEnum(rawValue: self) {
        case .success: return nil
        case .success_authenticated: return nil
        case .success_non_authenticated: return nil
        case .bad_state: return "bad_state"
        case .stream: return "stream"
        case .parse: return "parse"
        case .connection_refused: return "connection_refused"
        case .memory: return "memory"
        case .fatal: return "fatal"
        case .protocol: return "protocol"
        case .dont_accept_connection: return "dont_accept_connection"
        case .append: return "append"
        case .noop: return "noop"
        case .logout: return "logout"
        case .capability: return "capability"
        case .check: return "check"
        case .close: return "close"
        case .expunge: return "expunge"
        case .copy: return "copy"
        case .uid_copy: return "uid_copy"
        case .move: return "move"
        case .uid_move: return "uid_move"
        case .create: return "create"
        case .delete: return "delete"
        case .examine: return "examine"
        case .fetch: return "fetch"
        case .uid_fetch: return "uid_fetch"
        case .list: return "list"
        case .login: return "login"
        case .lsub: return "lsub"
        case .rename: return "rename"
        case .search: return "search"
        case .uid_search: return "uid_search"
        case .select: return "select"
        case .status: return "status"
        case .store: return "store"
        case .uid_store: return "uid_store"
        case .subscribe: return "subscribe"
        case .unsubscribe: return "unsubscribe"
        case .starttls: return "starttls"
        case .inval: return "inval"
        case .extension: return "extension"
        case .sasl: return "sasl"
        case .ssl: return "ssl"
        case .needs_more_data: return "needs_more_data"
        case .custom_command: return "custom_command"
        case .clientid: return "clientid"
        default: return "unknown error"
        }
    }
}
