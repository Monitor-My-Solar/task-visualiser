import Foundation

final class SMCThermalMonitor: @unchecked Sendable {

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

    /// Tests whether SMC fan writes are permitted (requires root on Apple Silicon).
    lazy var canControlFans: Bool = {
        guard SMCHelpers.isAvailable else { return false }
        // Try a no-op write: set mode to its current value
        let modeKey = "F0Md"
        let current = SMCHelpers.readRawKey(modeKey)
        let testByte = current?.bytes.first ?? 0
        return SMCHelpers.writeRawKey(modeKey, dataType: SMCHelpers.dataTypeUI8, bytes: [testByte])
    }()

    func setFanSpeed(fanIndex: Int, targetRPM: Double) {
        guard canControlFans else { return }

        let minKey = String(format: "F%dMn", fanIndex)
        let maxKey = String(format: "F%dMx", fanIndex)
        let minRPM = SMCHelpers.readDouble(minKey) ?? 0
        let maxRPM = SMCHelpers.readDouble(maxKey) ?? 6500

        let clamped = max(minRPM, min(targetRPM, maxRPM))

        let modeKey = String(format: "F%dMd", fanIndex)
        _ = SMCHelpers.writeRawKey(modeKey, dataType: SMCHelpers.dataTypeUI8, bytes: [1])

        // Write target RPM — match the data type the SMC actually uses for this key
        let targetKey = String(format: "F%dTg", fanIndex)
        if let existing = SMCHelpers.readRawKey(targetKey) {
            let encoded: [UInt8]
            let dataType: UInt32
            if existing.dataType == SMCHelpers.dataTypeFLT {
                encoded = SMCHelpers.encodeFLT(clamped)
                dataType = SMCHelpers.dataTypeFLT
            } else {
                encoded = SMCHelpers.encodeFPE2(clamped)
                dataType = SMCHelpers.dataTypeFPE2
            }
            _ = SMCHelpers.writeRawKey(targetKey, dataType: dataType, bytes: encoded)
        }
    }

    func setFanAuto(fanIndex: Int) {
        guard canControlFans else { return }
        let modeKey = String(format: "F%dMd", fanIndex)
        _ = SMCHelpers.writeRawKey(modeKey, dataType: SMCHelpers.dataTypeUI8, bytes: [0])
    }

    func restoreAllFansToAuto() {
        guard canControlFans else { return }
        let fanCount = Int(SMCHelpers.readDouble("FNum") ?? 0)
        for i in 0..<fanCount {
            setFanAuto(fanIndex: i)
        }
    }

    // MARK: - Cached state (protected by lock)

    private let lock = NSLock()
    private var discoveredSensors: [DiscoveredSensor]?
    private var temperatureCache: [String: Double] = [:]
    private var systemPowerCache: Double?
    private var cpuPowerCache: Double?
    private var gpuPowerCache: Double?

    private struct DiscoveredSensor {
        let key: String
        let label: String
    }

    // MARK: - Fan reading

    private func readFans() -> [ThermalUsage.FanStatus] {
        guard let fanCount = SMCHelpers.readDouble("FNum"), fanCount > 0, fanCount <= 10 else { return [] }

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

    // MARK: - Temperature reading (discovery + memoized values)

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
        let cached = discoveredSensors
        var tempCache = temperatureCache
        lock.unlock()

        // Step 1: Discover which keys exist (only once, by raw read not value)
        let sensors: [DiscoveredSensor]
        if let cached {
            sensors = cached
        } else {
            var discovered: [DiscoveredSensor] = []
            for (key, label) in Self.knownTemperatureKeys {
                if SMCHelpers.readRawKey(key) != nil {
                    discovered.append(DiscoveredSensor(key: key, label: label))
                }
            }
            // Only lock in the result if we found sensors; retry next poll otherwise
            if !discovered.isEmpty {
                lock.lock()
                discoveredSensors = discovered
                lock.unlock()
            }
            sensors = discovered
        }

        // Step 2: Read each discovered sensor, update cache on valid reads
        var readings: [ThermalUsage.TemperatureReading] = []
        for sensor in sensors {
            if let celsius = SMCHelpers.readDouble(sensor.key), celsius > 0 && celsius < 200 {
                tempCache[sensor.key] = celsius
            }
            // Always emit from cache — stable list, last-known-good value
            if let value = tempCache[sensor.key] {
                readings.append(ThermalUsage.TemperatureReading(
                    id: sensor.key,
                    label: sensor.label,
                    celsius: value
                ))
            }
        }

        lock.lock()
        temperatureCache = tempCache
        lock.unlock()

        return readings
    }

    // MARK: - Power reading (memoized, robust decoding)

    /// Reads a power SMC key and returns watts, trying multiple decode strategies.
    private func readPowerWatts(_ key: String) -> Double? {
        guard let raw = SMCHelpers.readRawKey(key) else { return nil }
        let bytes = raw.bytes

        // 1. Standard type-aware decoder
        if let value = SMCHelpers.decodeRawResult(raw) {
            if value > 0 && value < 500 { return value }
            // Some SMC implementations report milliwatts
            if value >= 500 && value < 500_000 { return value / 1000.0 }
        }

        // 2. Fallback: IEEE 32-bit float (little-endian)
        if bytes.count >= 4 {
            let bits = UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) |
                       (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24)
            let f = Float(bitPattern: bits)
            if f.isFinite && f > 0 && f < 500 { return Double(f) }
        }

        // 3. Fallback: sp78 signed 7.8 fixed-point
        if bytes.count >= 2 {
            let raw16 = Int16(bitPattern: (UInt16(bytes[0]) << 8) | UInt16(bytes[1]))
            let val = Double(raw16) / 256.0
            if val > 0 && val < 500 { return val }
        }

        return nil
    }

    private func readPower() -> (system: Double?, cpu: Double?, gpu: Double?) {
        lock.lock()
        var sysPower = systemPowerCache
        var cpuPwr = cpuPowerCache
        var gpuPwr = gpuPowerCache
        lock.unlock()

        if let v = readPowerWatts("PSTR") { sysPower = v }
        if let v = readPowerWatts("PCPC") { cpuPwr = v }
        if let v = readPowerWatts("PCPG") { gpuPwr = v }

        lock.lock()
        systemPowerCache = sysPower
        cpuPowerCache = cpuPwr
        gpuPowerCache = gpuPwr
        lock.unlock()

        return (sysPower, cpuPwr, gpuPwr)
    }
}
