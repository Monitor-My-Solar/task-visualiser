import Foundation
import IOKit

final class GPUMonitor: Sendable {

    nonisolated func snapshot() -> GPUUsage {
        let rawDevices = IOKitHelpers.readGPUPerformanceStatistics()

        let devices = rawDevices.enumerated().map { index, raw in
            GPUUsage.DeviceUsage(
                id: index,
                name: raw.name,
                utilization: raw.utilization,
                vramUsed: raw.vramUsed,
                vramTotal: raw.vramTotal
            )
        }

        let maxUtilization = devices.map(\.utilization).max() ?? 0

        return GPUUsage(
            utilization: maxUtilization,
            devices: devices,
            timestamp: .now
        )
    }
}
