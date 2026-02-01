import Foundation

struct BatteryUsage: Sendable {
    var level: Double
    var isCharging: Bool
    var isPluggedIn: Bool
    var powerSource: PowerSource
    var cycleCount: Int?
    var health: Double?
    var timeRemaining: TimeInterval?
    var isPresent: Bool
    var hasBattery: Bool
    var thermalState: ThermalState
    var timestamp: Date

    enum PowerSource: String, Sendable {
        case battery = "Battery"
        case ac = "AC Power"
        case ups = "UPS"
        case unknown = "Unknown"
    }

    enum ThermalState: String, Sendable {
        case nominal = "Nominal"
        case fair = "Fair"
        case serious = "Serious"
        case critical = "Critical"

        init(from processThermalState: ProcessInfo.ThermalState) {
            switch processThermalState {
            case .nominal: self = .nominal
            case .fair: self = .fair
            case .serious: self = .serious
            case .critical: self = .critical
            @unknown default: self = .nominal
            }
        }
    }

    static let zero = BatteryUsage(
        level: 0,
        isCharging: false,
        isPluggedIn: false,
        powerSource: .ac,
        cycleCount: nil,
        health: nil,
        timeRemaining: nil,
        isPresent: true,
        hasBattery: false,
        thermalState: .nominal,
        timestamp: .now
    )
}
