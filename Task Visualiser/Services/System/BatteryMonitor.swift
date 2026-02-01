import Foundation
import IOKit.ps

final class BatteryMonitor: Sendable {

    nonisolated func snapshot() -> BatteryUsage {
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as? [CFTypeRef] ?? []

        guard let first = psList.first,
              let desc = IOPSGetPowerSourceDescription(psInfo, first)?.takeUnretainedValue() as? [String: Any] else {
            return BatteryUsage(
                level: 0,
                isCharging: false,
                isPluggedIn: false,
                powerSource: .unknown,
                cycleCount: nil,
                health: nil,
                timeRemaining: nil,
                isPresent: false,
                thermalState: .init(from: ProcessInfo.processInfo.thermalState),
                timestamp: .now
            )
        }

        let currentCapacity = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        let level = maxCapacity > 0 ? Double(currentCapacity) / Double(maxCapacity) * 100.0 : 0

        let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false
        let powerSourceState = desc[kIOPSPowerSourceStateKey] as? String ?? ""
        let isPluggedIn = powerSourceState == kIOPSACPowerValue

        let powerSource: BatteryUsage.PowerSource
        if isPluggedIn {
            powerSource = .ac
        } else if powerSourceState == kIOPSBatteryPowerValue {
            powerSource = .battery
        } else {
            powerSource = .unknown
        }

        let cycleCount = desc["BatteryCycleCount"] as? Int

        let healthString = desc[kIOPSBatteryHealthKey] as? String
        let health: Double?
        if let healthString {
            switch healthString {
            case kIOPSGoodValue: health = 100
            case kIOPSFairValue: health = 50
            case kIOPSPoorValue: health = 10
            default: health = nil
            }
        } else {
            health = nil
        }

        let timeRemainingRaw = IOPSGetTimeRemainingEstimate()
        let timeRemaining: TimeInterval?
        if timeRemainingRaw == kIOPSTimeRemainingUnlimited {
            timeRemaining = nil
        } else if timeRemainingRaw == kIOPSTimeRemainingUnknown {
            timeRemaining = nil
        } else {
            timeRemaining = timeRemainingRaw
        }

        return BatteryUsage(
            level: level,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            powerSource: powerSource,
            cycleCount: cycleCount,
            health: health,
            timeRemaining: timeRemaining,
            isPresent: true,
            thermalState: .init(from: ProcessInfo.processInfo.thermalState),
            timestamp: .now
        )
    }
}
