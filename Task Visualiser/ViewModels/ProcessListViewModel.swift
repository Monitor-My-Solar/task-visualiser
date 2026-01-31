import Foundation

struct ProcessMetricSnapshot: Sendable {
    let timestamp: Date
    let cpuUsage: Double
    let memoryBytes: UInt64
}

@Observable
final class ProcessListViewModel {
    private let provider: ProcessProvider
    private var pollingTask: Task<Void, Never>?
    private var trackedPID: pid_t?

    var processes: [ProcessEntry] = []
    var searchText: String = ""
    var selectedPID: pid_t?
    private(set) var selectedProcessHistory: [ProcessMetricSnapshot] = []
    var sortOrder: [KeyPathComparator<ProcessEntry>] = [
        KeyPathComparator(\ProcessEntry.cpuUsage, order: .reverse)
    ]

    var filteredProcesses: [ProcessEntry] {
        var result = processes
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                "\($0.pid)".contains(searchText)
            }
        }
        result.sort(using: sortOrder)
        return result
    }

    var selectedProcess: ProcessEntry? {
        guard let pid = selectedPID else { return nil }
        return processes.first(where: { $0.pid == pid })
    }

    init(isSandboxed: Bool) {
        if isSandboxed {
            provider = SandboxedProcessProvider()
        } else {
            provider = FullProcessProvider()
        }
    }

    func startPolling() {
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() {
        processes = provider.listProcesses()

        if let pid = selectedPID,
           let process = processes.first(where: { $0.pid == pid }) {
            if pid != trackedPID {
                selectedProcessHistory.removeAll()
                trackedPID = pid
            }
            selectedProcessHistory.append(ProcessMetricSnapshot(
                timestamp: .now,
                cpuUsage: process.cpuUsage,
                memoryBytes: process.memoryBytes
            ))
            if selectedProcessHistory.count > 120 {
                selectedProcessHistory.removeFirst(selectedProcessHistory.count - 120)
            }
        } else {
            selectedProcessHistory.removeAll()
            trackedPID = nil
            if selectedPID != nil, !processes.contains(where: { $0.pid == selectedPID }) {
                selectedPID = nil
            }
        }
    }

    func terminateSelected() -> Bool {
        guard let pid = selectedPID else { return false }
        return provider.terminate(pid: pid)
    }

    func forceTerminateSelected() -> Bool {
        guard let pid = selectedPID else { return false }
        return provider.forceTerminate(pid: pid)
    }
}
