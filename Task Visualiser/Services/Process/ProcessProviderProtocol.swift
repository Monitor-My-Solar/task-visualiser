import Foundation

protocol ProcessProvider: Sendable {
    func listProcesses() -> [ProcessEntry]
    func terminate(pid: pid_t) -> Bool
    func forceTerminate(pid: pid_t) -> Bool
}
