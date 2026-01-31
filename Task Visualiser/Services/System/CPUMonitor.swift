import Foundation

final class CPUMonitor: Sendable {

    nonisolated func snapshot() -> CPUUsage {
        let total = totalUsage()
        let cores = perCoreUsage()
        return CPUUsage(
            totalUsage: total.total,
            userUsage: total.user,
            systemUsage: total.system,
            idleUsage: total.idle,
            coreUsages: cores,
            timestamp: .now
        )
    }

    // MARK: - State for delta calculation (uses locks for thread safety)

    private let lock = NSLock()
    private let prevTotal = UnsafeMutablePointer<MachHelpers.CPULoadInfo?>.allocate(capacity: 1)
    private let prevCores = UnsafeMutablePointer<[MachHelpers.PerCoreCPUTicks]?>.allocate(capacity: 1)

    init() {
        prevTotal.initialize(to: nil)
        prevCores.initialize(to: nil)
    }

    deinit {
        prevTotal.deinitialize(count: 1)
        prevTotal.deallocate()
        prevCores.deinitialize(count: 1)
        prevCores.deallocate()
    }

    private func totalUsage() -> (total: Double, user: Double, system: Double, idle: Double) {
        guard let current = MachHelpers.hostCPULoadInfo() else {
            return (0, 0, 0, 100)
        }

        lock.lock()
        let previous = prevTotal.pointee
        prevTotal.pointee = current
        lock.unlock()

        guard let prev = previous else {
            return (0, 0, 0, 100)
        }

        let userDelta = Double(current.userTicks &- prev.userTicks)
        let systemDelta = Double(current.systemTicks &- prev.systemTicks)
        let idleDelta = Double(current.idleTicks &- prev.idleTicks)
        let niceDelta = Double(current.niceTicks &- prev.niceTicks)
        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta

        guard totalDelta > 0 else { return (0, 0, 0, 100) }

        let user = ((userDelta + niceDelta) / totalDelta) * 100
        let system = (systemDelta / totalDelta) * 100
        let idle = (idleDelta / totalDelta) * 100

        return (user + system, user, system, idle)
    }

    private func perCoreUsage() -> [CPUUsage.CoreUsage] {
        guard let currentCores = MachHelpers.perCoreCPULoadInfo() else { return [] }

        lock.lock()
        let previousCores = prevCores.pointee
        prevCores.pointee = currentCores
        lock.unlock()

        guard let prev = previousCores, prev.count == currentCores.count else {
            return currentCores.enumerated().map { CPUUsage.CoreUsage(id: $0.offset, usage: 0) }
        }

        return currentCores.enumerated().map { index, core in
            let p = prev[index]
            let userDelta = Double(core.user &- p.user)
            let systemDelta = Double(core.system &- p.system)
            let idleDelta = Double(core.idle &- p.idle)
            let niceDelta = Double(core.nice &- p.nice)
            let total = userDelta + systemDelta + idleDelta + niceDelta

            let usage = total > 0 ? ((userDelta + systemDelta + niceDelta) / total) * 100 : 0
            return CPUUsage.CoreUsage(id: index, usage: usage)
        }
    }
}
