import Foundation
import AppKit
import Darwin

final class SandboxedProcessProvider: ProcessProvider, @unchecked Sendable {
    private var previousCPUTimes: [pid_t: UInt64] = [:]
    private var previousTimestamp: TimeInterval = 0

    private static let machTimebaseNanos: Double = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return Double(info.numer) / Double(info.denom)
    }()

    func listProcesses() -> [ProcessEntry] {
        let apps = NSWorkspace.shared.runningApplications
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = previousTimestamp > 0 ? now - previousTimestamp : 0

        var currentCPUTimes: [pid_t: UInt64] = [:]

        let entries = apps.compactMap { app -> ProcessEntry? in
            guard let name = app.localizedName ?? app.bundleIdentifier else { return nil }
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

            return ProcessEntry(
                id: pid,
                name: name,
                bundleIdentifier: app.bundleIdentifier,
                cpuUsage: cpuUsage,
                memoryBytes: memoryBytes,
                user: NSUserName(),
                isActive: app.isActive,
                icon: app.icon
            )
        }

        previousCPUTimes = currentCPUTimes
        previousTimestamp = now
        return entries
    }

    func terminate(pid: pid_t) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) else {
            return false
        }
        return app.terminate()
    }

    func forceTerminate(pid: pid_t) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) else {
            return false
        }
        return app.forceTerminate()
    }
}
