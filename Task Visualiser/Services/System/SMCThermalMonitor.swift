import Foundation

final class SMCThermalMonitor: Sendable {

    nonisolated func snapshot() -> ThermalUsage {
        guard SMCHelpers.isAvailable else { return .zero }

        let fans = readFans()
        let temperatures = readTemperatures()
        let (systemPower, cpuPower, gpuPower) = readPower()

        return ThermalUsage(
            fans: fans,
            temperatures: temperatures,
            systemPowerWatts: systemPower,
            cpuPowerWatts: cpuPower,
            gpuPowerWatts: gpuPower,
            timestamp: .now
        )
    }

    // MARK: - Fan control

    func setFanSpeed(fanIndex: Int, targetRPM: Double) {
        guard SMCHelpers.isAvailable else { return }

        // Read min/max to clamp
        let minKey = String(format: "F%dMn", fanIndex)
        let maxKey = String(format: "F%dMx", fanIndex)
        let minRPM = SMCHelpers.readDouble(minKey) ?? 0
        let maxRPM = SMCHelpers.readDouble(maxKey) ?? 6500

        let clamped = max(minRPM, min(targetRPM, maxRPM))

        // Set mode to forced (1)
        let modeKey = String(format: "F%dMd", fanIndex)
        _ = SMCHelpers.writeRawKey(modeKey, dataType: SMCHelpers.dataTypeUI8, bytes: [1])

        // Write target RPM
        let targetKey = String(format: "F%dTg", fanIndex)
        let encoded = SMCHelpers.encodeFPE2(clamped)
        _ = SMCHelpers.writeRawKey(targetKey, dataType: SMCHelpers.dataTypeFPE2, bytes: encoded)
    }

    func setFanAuto(fanIndex: Int) {
        guard SMCHelpers.isAvailable else { return }
        let modeKey = String(format: "F%dMd", fanIndex)
        _ = SMCHelpers.writeRawKey(modeKey, dataType: SMCHelpers.dataTypeUI8, bytes: [0])
    }

    func restoreAllFansToAuto() {
        guard SMCHelpers.isAvailable else { return }
        let fanCount = Int(SMCHelpers.readDouble("FNum") ?? 0)
        for i in 0..<fanCount {
            setFanAuto(fanIndex: i)
        }
    }

    // MARK: - State for temperature discovery

    private let lock = NSLock()
    private let discoveredKeysPtr = UnsafeMutablePointer<[DiscoveredSensor]?>.allocate(capacity: 1)

    private struct DiscoveredSensor {
        let key: String
        let label: String
    }

    init() {
        discoveredKeysPtr.initialize(to: nil)
    }

    deinit {
        discoveredKeysPtr.deinitialize(count: 1)
        discoveredKeysPtr.deallocate()
    }

    // MARK: - Fan reading

    private func readFans() -> [ThermalUsage.FanStatus] {
        guard let fanCount = SMCHelpers.readDouble("FNum"), fanCount > 0 else { return [] }

        var fans: [ThermalUsage.FanStatus] = []
        for i in 0..<Int(fanCount) {
            let acKey = String(format: "F%dAc", i)
            let mnKey = String(format: "F%dMn", i)
            let mxKey = String(format: "F%dMx", i)
            let tgKey = String(format: "F%dTg", i)
            let mdKey = String(format: "F%dMd", i)

            let currentRPM = SMCHelpers.readDouble(acKey) ?? 0
            let minRPM = SMCHelpers.readDouble(mnKey) ?? 0
            let maxRPM = SMCHelpers.readDouble(mxKey) ?? 0
            let targetRPM = SMCHelpers.readDouble(tgKey) ?? 0
            let modeVal = SMCHelpers.readDouble(mdKey) ?? 0

            let mode: ThermalUsage.FanMode = modeVal > 0 ? .forced : .auto

            fans.append(ThermalUsage.FanStatus(
                id: i,
                currentRPM: currentRPM,
                minRPM: minRPM,
                maxRPM: maxRPM,
                targetRPM: targetRPM,
                mode: mode
            ))
        }
        return fans
    }

    // MARK: - Temperature reading (with discovery cache)

    private static let knownTemperatureKeys: [(key: String, label: String)] = [
        // CPU
        ("TC0P", "CPU Proximity"),
        ("TC0D", "CPU Die"),
        ("TC0E", "CPU Die 2"),
        ("TC0F", "CPU Die 3"),
        ("TC1C", "CPU Core 1"),
        ("TC2C", "CPU Core 2"),
        ("TC3C", "CPU Core 3"),
        ("TC4C", "CPU Core 4"),
        ("TC5C", "CPU Core 5"),
        ("TC6C", "CPU Core 6"),
        ("TC7C", "CPU Core 7"),
        ("TC8C", "CPU Core 8"),
        // Apple Silicon CPU
        ("Tp09", "CPU Efficiency Core 1"),
        ("Tp0T", "CPU Efficiency Core 2"),
        ("Tp01", "CPU Performance Core 1"),
        ("Tp05", "CPU Performance Core 2"),
        ("Tp0D", "CPU Performance Core 3"),
        ("Tp0H", "CPU Performance Core 4"),
        ("Tp0L", "CPU Performance Core 5"),
        ("Tp0P", "CPU Performance Core 6"),
        // GPU
        ("TG0P", "GPU Proximity"),
        ("TG0D", "GPU Die"),
        ("Tg05", "GPU 1"),
        ("Tg0D", "GPU 2"),
        ("Tg0f", "GPU 3"),
        // SSD / Storage
        ("TH0A", "SSD A"),
        ("TH0B", "SSD B"),
        ("TH0a", "SSD Slot A"),
        ("TH0b", "SSD Slot B"),
        // Ambient / Other
        ("TA0P", "Ambient"),
        ("TA1P", "Ambient 2"),
        ("TB0T", "Battery"),
        ("TB1T", "Battery 2"),
        ("TW0P", "Wireless"),
        ("Tm0P", "Mainboard"),
        ("Tp0C", "Power Supply"),
        ("TM0P", "Memory Proximity"),
        ("TN0P", "Northbridge Proximity"),
    ]

    private func readTemperatures() -> [ThermalUsage.TemperatureReading] {
        lock.lock()
        let cached = discoveredKeysPtr.pointee
        lock.unlock()

        let sensors: [DiscoveredSensor]
        if let cached {
            sensors = cached
        } else {
            // Discovery: probe all known keys, cache which exist
            var discovered: [DiscoveredSensor] = []
            for (key, label) in Self.knownTemperatureKeys {
                if let val = SMCHelpers.readDouble(key), val > 0 && val < 200 {
                    discovered.append(DiscoveredSensor(key: key, label: label))
                }
            }
            lock.lock()
            discoveredKeysPtr.pointee = discovered
            lock.unlock()
            sensors = discovered
        }

        var readings: [ThermalUsage.TemperatureReading] = []
        for sensor in sensors {
            if let celsius = SMCHelpers.readDouble(sensor.key), celsius > 0 && celsius < 200 {
                readings.append(ThermalUsage.TemperatureReading(
                    id: sensor.key,
                    label: sensor.label,
                    celsius: celsius
                ))
            }
        }
        return readings
    }

    // MARK: - Power reading

    private func readPower() -> (system: Double?, cpu: Double?, gpu: Double?) {
        let system = SMCHelpers.readDouble("PSTR")
        let cpu = SMCHelpers.readDouble("PCPC")
        let gpu = SMCHelpers.readDouble("PCPG")
        return (system, cpu, gpu)
    }
}
