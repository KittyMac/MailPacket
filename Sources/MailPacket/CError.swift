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

// MARK: - smtp

// smtp uses its own error enum (MAILSMTP_ERROR_XXX), which does not line up
// with the imap one, so it gets its own mapping
typealias CSMTPError = Int32

extension CSMTPError {
    private enum CSMTPErrorEnum: Int32 {
        case success = 0
        case unexpected_code
        case service_not_available
        case stream
        case hostname
        case not_implemented
        case action_not_taken
        case exceed_storage_allocation
        case in_processing
        case insufficient_system_storage
        case mailbox_unavailable
        case mailbox_name_not_allowed
        case bad_sequence_of_command
        case user_not_local
        case transaction_failed
        case memory
        case auth_not_supported
        case auth_login
        case auth_required
        case auth_too_weak
        case auth_transition_needed
        case auth_temporary_failure
        case auth_encryption_required
        case starttls_temporary_failure
        case starttls_not_supported
        case connection_refused
        case auth_authentication_failed
        case ssl
        case clientid_not_supported
    }
    
    func toSMTPString(_ detials: String?) -> String? {
        switch CSMTPErrorEnum(rawValue: self) {
        case .success: return nil
        case .unexpected_code: return "unexpected_code: \(detials ?? "unknown")"
        case .service_not_available: return "service_not_available: \(detials ?? "unknown")"
        case .stream: return "stream: \(detials ?? "unknown")"
        case .hostname: return "hostname: \(detials ?? "unknown")"
        case .not_implemented: return "not_implemented: \(detials ?? "unknown")"
        case .action_not_taken: return "action_not_taken: \(detials ?? "unknown")"
        case .exceed_storage_allocation: return "exceed_storage_allocation: \(detials ?? "unknown")"
        case .in_processing: return "in_processing: \(detials ?? "unknown")"
        case .insufficient_system_storage: return "insufficient_system_storage: \(detials ?? "unknown")"
        case .mailbox_unavailable: return "mailbox_unavailable: \(detials ?? "unknown")"
        case .mailbox_name_not_allowed: return "mailbox_name_not_allowed: \(detials ?? "unknown")"
        case .bad_sequence_of_command: return "bad_sequence_of_command: \(detials ?? "unknown")"
        case .user_not_local: return "user_not_local: \(detials ?? "unknown")"
        case .transaction_failed: return "transaction_failed: \(detials ?? "unknown")"
        case .memory: return "memory: \(detials ?? "unknown")"
        case .auth_not_supported: return "auth_not_supported: \(detials ?? "unknown")"
        case .auth_login: return "auth_login: \(detials ?? "unknown")"
        case .auth_required: return "auth_required: \(detials ?? "unknown")"
        case .auth_too_weak: return "auth_too_weak: \(detials ?? "unknown")"
        case .auth_transition_needed: return "auth_transition_needed: \(detials ?? "unknown")"
        case .auth_temporary_failure: return "auth_temporary_failure: \(detials ?? "unknown")"
        case .auth_encryption_required: return "auth_encryption_required: \(detials ?? "unknown")"
        case .starttls_temporary_failure: return "starttls_temporary_failure: \(detials ?? "unknown")"
        case .starttls_not_supported: return "starttls_not_supported: \(detials ?? "unknown")"
        case .connection_refused: return "connection_refused: \(detials ?? "unknown")"
        case .auth_authentication_failed: return "auth_authentication_failed: \(detials ?? "unknown")"
        case .ssl: return "ssl: \(detials ?? "unknown")"
        case .clientid_not_supported: return "clientid_not_supported: \(detials ?? "unknown")"
        default: return "unknown smtp error: \(detials ?? "unknown")"
        }
    }
}

#endif