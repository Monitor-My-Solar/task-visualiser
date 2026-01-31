import Foundation
import AppKit
import Darwin

@Observable
final class PinnedProcessService {
    private(set) var pinnedProcesses: [PinnedProcess] = []
    private(set) var liveData: [String: ProcessLiveData] = [:]

    private var previousCPUTimes: [pid_t: UInt64] = [:]
    private var previousTimestamp: TimeInterval = 0
    private var pollingTask: Task<Void, Never>?

    private static let machTimebaseNanos: Double = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return Double(info.numer) / Double(info.denom)
    }()

    struct ProcessLiveData {
        var pid: pid_t
        var name: String
        var cpuUsage: Double
        var memoryBytes: UInt64
        var icon: NSImage?
        var isRunning: Bool
        var cpuHistory: [Double] = []
        var memoryHistory: [Double] = []
    }

    init() {
        loadPinned()
    }

    // MARK: - Pin Management

    func pin(identifier: String, displayName: String) {
        guard !pinnedProcesses.contains(where: { $0.identifier == identifier }) else { return }
        pinnedProcesses.append(PinnedProcess(identifier: identifier, displayName: displayName))
        savePinned()
    }

    func unpin(identifier: String) {
        pinnedProcesses.removeAll { $0.identifier == identifier }
        liveData.removeValue(forKey: identifier)
        savePinned()
    }

    func isPinned(identifier: String) -> Bool {
        pinnedProcesses.contains { $0.identifier == identifier }
    }

    // MARK: - Polling

    func start() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.poll()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func poll() {
        guard !pinnedProcesses.isEmpty else { return }

        let apps = NSWorkspace.shared.runningApplications
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = previousTimestamp > 0 ? now - previousTimestamp : 0
        var currentCPUTimes: [pid_t: UInt64] = [:]

        for pinned in pinnedProcesses {
            let app = apps.first { a in
                if let bid = a.bundleIdentifier, bid == pinned.identifier {
                    return true
                }
                return a.localizedName == pinned.identifier
            }

            guard let app else {
                if var data = liveData[pinned.identifier] {
                    data.isRunning = false
                    data.cpuUsage = 0
                    liveData[pinned.identifier] = data
                }
                continue
            }

            let pid = app.processIdentifier

            var taskInfo = proc_taskinfo()
            let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.stride)
            let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)

            var cpuUsage: Double = 0
            var memoryBytes: UInt64 = 0

            if result == taskInfoSize {
                memoryBytes = UInt64(taskInfo.pti_resident_size)
                let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
                currentCPUTimes[pid] = totalTime

                if elapsed > 0, let previous = previousCPUTimes[pid] {
                    let deltaMach = totalTime > previous ? totalTime - previous : 0
                    let deltaNanos = Double(deltaMach) * Self.machTimebaseNanos
                    let deltaSeconds = deltaNanos / 1_000_000_000
                    cpuUsage = (deltaSeconds / elapsed) * 100
                }
            }

            var data = liveData[pinned.identifier] ?? ProcessLiveData(
                pid: pid,
                name: pinned.displayName,
                cpuUsage: 0,
                memoryBytes: 0,
                icon: app.icon,
                isRunning: true
            )

            data.pid = pid
            data.cpuUsage = cpuUsage
            data.memoryBytes = memoryBytes
            data.icon = app.icon
            data.isRunning = true

            data.cpuHistory.append(cpuUsage)
            if data.cpuHistory.count > 60 { data.cpuHistory.removeFirst() }

            data.memoryHistory.append(Double(memoryBytes))
            if data.memoryHistory.count > 60 { data.memoryHistory.removeFirst() }

            liveData[pinned.identifier] = data
        }

        previousCPUTimes = currentCPUTimes
        previousTimestamp = now
    }

    // MARK: - Persistence

    private func loadPinned() {
        guard let data = UserDefaults.standard.data(forKey: "pinnedProcesses"),
              let decoded = try? JSONDecoder().decode([PinnedProcess].self, from: data) else {
            return
        }
        pinnedProcesses = decoded
    }

    private func savePinned() {
        if let data = try? JSONEncoder().encode(pinnedProcesses) {
            UserDefaults.standard.set(data, forKey: "pinnedProcesses")
        }
    }
}
