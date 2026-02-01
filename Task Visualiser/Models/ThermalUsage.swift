import Foundation

struct ThermalUsage: Sendable {
    var fans: [FanStatus]
    var temperatures: [TemperatureReading]
    var systemPowerWatts: Double?
    var cpuPowerWatts: Double?
    var gpuPowerWatts: Double?
    var timestamp: Date

    struct FanStatus: Identifiable, Sendable {
        let id: Int
        var currentRPM: Double
        var minRPM: Double
        var maxRPM: Double
        var targetRPM: Double
        var mode: FanMode

        var percentOfMax: Double {
            guard maxRPM > minRPM else { return 0 }
            return min(max((currentRPM - minRPM) / (maxRPM - minRPM) * 100, 0), 100)
        }
    }

    enum FanMode: String, Sendable {
        case auto = "Auto"
        case forced = "Manual"
    }

    struct TemperatureReading: Identifiable, Sendable {
        var id: String  // SMC key (e.g. "TC0P")
        var label: String
        var celsius: Double
    }

    var cpuTemperature: Double? {
        temperatures.first(where: { $0.id == "TC0P" || $0.id == "Tp09" })?.celsius
    }

    var gpuTemperature: Double? {
        temperatures.first(where: { $0.id == "TG0P" || $0.id == "Tg05" })?.celsius
    }

    var fanCount: Int { fans.count }

    var hasData: Bool {
        !fans.isEmpty || !temperatures.isEmpty || systemPowerWatts != nil
    }

    static let zero = ThermalUsage(
        fans: [],
        temperatures: [],
        systemPowerWatts: nil,
        cpuPowerWatts: nil,
        gpuPowerWatts: nil,
        timestamp: .now
    )
}
