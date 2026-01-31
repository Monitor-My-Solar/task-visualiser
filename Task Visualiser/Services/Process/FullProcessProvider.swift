import Foundation
import Darwin
import AppKit

final class FullProcessProvider: ProcessProvider, @unchecked Sendable {
    private var previousCPUTimes: [pid_t: UInt64] = [:]
    private var previousTimestamp: TimeInterval = 0

    private static let machTimebaseNanos: Double = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return Double(info.numer) / Double(info.denom)
    }()

    func listProcesses() -> [ProcessEntry] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size: size_t = 0

        guard sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0) == 0, size > 0 else {
            return []
        }

        let count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)

        guard sysctl(&mib, UInt32(mib.count), &procs, &size, nil, 0) == 0 else {
            return []
        }

        let actualCount = size / MemoryLayout<kinfo_proc>.stride
        let runningApps = NSWorkspace.shared.runningApplications
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = previousTimestamp > 0 ? now - previousTimestamp : 0

        var currentCPUTimes: [pid_t: UInt64] = [:]

        let entries = (0..<actualCount).compactMap { i -> ProcessEntry? in
            let proc = procs[i]
            let pid = proc.kp_proc.p_pid
            guard pid > 0 else { return nil }

            let name = withUnsafePointer(to: proc.kp_proc.p_comm) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) { cStr in
                    String(cString: cStr)
                }
            }

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

            let uid = proc.kp_eproc.e_ucred.cr_uid
            let user = userName(for: uid)

            let matchingApp = runningApps.first(where: { $0.processIdentifier == pid })

            return ProcessEntry(
                id: pid,
                name: name,
                bundleIdentifier: matchingApp?.bundleIdentifier,
                cpuUsage: cpuUsage,
                memoryBytes: memoryBytes,
                user: user,
                isActive: proc.kp_proc.p_stat == SRUN,
                icon: matchingApp?.icon
            )
        }

        previousCPUTimes = currentCPUTimes
        previousTimestamp = now
        return entries
    }

    func terminate(pid: pid_t) -> Bool {
        Darwin.kill(pid, SIGTERM) == 0
    }

    func forceTerminate(pid: pid_t) -> Bool {
        Darwin.kill(pid, SIGKILL) == 0
    }

    private func userName(for uid: uid_t) -> String {
        guard let pw = getpwuid(uid) else { return "\(uid)" }
        return String(cString: pw.pointee.pw_name)
    }
}
