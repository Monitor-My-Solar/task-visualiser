import Foundation
import IOKit

enum SMCHelpers {

    // MARK: - Public API

    static var isAvailable: Bool {
        Connection.shared.isOpen
    }

    static func readDouble(_ key: String) -> Double? {
        guard let raw = readRawKey(key) else { return nil }
        return decodeValue(raw.bytes, dataType: raw.dataType, dataSize: raw.dataSize)
    }

    static func decodeRawResult(_ result: SMCReadResult) -> Double? {
        decodeValue(result.bytes, dataType: result.dataType, dataSize: result.dataSize)
    }

    static func readRawKey(_ key: String) -> SMCReadResult? {
        Connection.shared.readKey(fourCharCode(key))
    }

    static func writeRawKey(_ key: String, dataType: UInt32, bytes: [UInt8]) -> Bool {
        Connection.shared.writeKey(fourCharCode(key), dataType: dataType, bytes: bytes)
    }

    struct SMCReadResult {
        var dataType: UInt32
        var dataSize: UInt32
        var bytes: [UInt8]
    }

    // MARK: - Value encoding (for writing fan target speeds)

    static func encodeFPE2(_ value: Double) -> [UInt8] {
        let clamped = max(0, min(value, 16383.75))
        let raw = UInt16(clamped * 4.0)
        return [UInt8(raw >> 8), UInt8(raw & 0xFF)]
    }

    static func encodeFLT(_ value: Double) -> [UInt8] {
        let bits = Float(value).bitPattern
        // Little-endian byte order (matching how SMC stores flt values)
        return [UInt8(bits & 0xFF), UInt8((bits >> 8) & 0xFF),
                UInt8((bits >> 16) & 0xFF), UInt8((bits >> 24) & 0xFF)]
    }

    // MARK: - FourCharCode helper

    static func fourCharCode(_ key: String) -> UInt32 {
        var result: UInt32 = 0
        for (i, char) in key.utf8.prefix(4).enumerated() {
            result |= UInt32(char) << (24 - i * 8)
        }
        return result
    }

    // MARK: - Data type constants (FourCharCodes)

    static let dataTypeFPE2 = fourCharCode("fpe2")
    static let dataTypeSP78 = fourCharCode("sp78")
    static let dataTypeFLT  = fourCharCode("flt ")
    static let dataTypeUI8  = fourCharCode("ui8 ")
    static let dataTypeUI16 = fourCharCode("ui16")
    static let dataTypeUI32 = fourCharCode("ui32")
    static let dataTypeSI8  = fourCharCode("si8 ")
    static let dataTypeSI16 = fourCharCode("si16")
    static let dataTypeSP1E = fourCharCode("sp1e")
    static let dataTypeSP3C = fourCharCode("sp3c")
    static let dataTypeSP4B = fourCharCode("sp4b")
    static let dataTypeSP5A = fourCharCode("sp5a")
    static let dataTypeSP69 = fourCharCode("sp69")
    static let dataTypeSP87 = fourCharCode("sp87")
    static let dataTypeFP1F = fourCharCode("fp1f")
    static let dataTypeFP2E = fourCharCode("fp2e")
    static let dataTypeFP3D = fourCharCode("fp3d")
    static let dataTypeFP4C = fourCharCode("fp4c")
    static let dataTypeFP5B = fourCharCode("fp5b")
    static let dataTypeFP6A = fourCharCode("fp6a")
    static let dataTypeFP79 = fourCharCode("fp79")
    static let dataTypeFP88 = fourCharCode("fp88")
    static let dataTypeFPA6 = fourCharCode("fpa6")
    static let dataTypeFPC4 = fourCharCode("fpc4")
    static let dataTypeFPE2_ = fourCharCode("fpe2")

    // MARK: - Value decoding

    private static func decodeValue(_ bytes: [UInt8], dataType: UInt32, dataSize: UInt32) -> Double? {
        switch dataType {
        case dataTypeFPE2:
            guard bytes.count >= 2 else { return nil }
            let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(raw) / 4.0

        case dataTypeSP78:
            guard bytes.count >= 2 else { return nil }
            let raw = Int16(bitPattern: (UInt16(bytes[0]) << 8) | UInt16(bytes[1]))
            return Double(raw) / 256.0

        case dataTypeFLT:
            guard bytes.count >= 4 else { return nil }
            // SMC stores IEEE float in little-endian byte order
            let bits = UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) |
                       (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24)
            return Double(Float(bitPattern: bits))

        case dataTypeUI8:
            guard bytes.count >= 1 else { return nil }
            return Double(bytes[0])

        case dataTypeUI16:
            guard bytes.count >= 2 else { return nil }
            return Double((UInt16(bytes[0]) << 8) | UInt16(bytes[1]))

        case dataTypeUI32:
            guard bytes.count >= 4 else { return nil }
            let val = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) |
                      (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
            return Double(val)

        case dataTypeSI8:
            guard bytes.count >= 1 else { return nil }
            return Double(Int8(bitPattern: bytes[0]))

        case dataTypeSI16:
            guard bytes.count >= 2 else { return nil }
            let raw = Int16(bitPattern: (UInt16(bytes[0]) << 8) | UInt16(bytes[1]))
            return Double(raw)

        default:
            return decodeFixedPoint(bytes, dataType: dataType)
        }
    }

    private static func decodeFixedPoint(_ bytes: [UInt8], dataType: UInt32) -> Double? {
        guard bytes.count >= 2 else { return nil }
        let raw16 = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])

        // Signed fixed-point formats: sp{int_bits}{frac_bits} where int+frac = 15 (sign bit)
        let signedFormats: [UInt32: Int] = [
            dataTypeSP1E: 14, dataTypeSP3C: 12, dataTypeSP4B: 11,
            dataTypeSP5A: 10, dataTypeSP69: 9, dataTypeSP87: 7
        ]

        if let fracBits = signedFormats[dataType] {
            let signed = Int16(bitPattern: raw16)
            return Double(signed) / Double(1 << fracBits)
        }

        // Unsigned fixed-point formats: fp{int_bits}{frac_bits} where int+frac = 16
        let unsignedFormats: [UInt32: Int] = [
            dataTypeFP1F: 15, dataTypeFP2E: 14, dataTypeFP3D: 13,
            dataTypeFP4C: 12, dataTypeFP5B: 11, dataTypeFP6A: 10,
            dataTypeFP79: 9, dataTypeFP88: 8, dataTypeFPA6: 6,
            dataTypeFPC4: 4
        ]

        if let fracBits = unsignedFormats[dataType] {
            return Double(raw16) / Double(1 << fracBits)
        }

        return nil
    }

    // MARK: - SMC Connection singleton

    private final class Connection: @unchecked Sendable {
        static let shared = Connection()

        private let lock = NSLock()
        private var connection: io_connect_t = 0
        private(set) var isOpen: Bool = false

        private init() {
            guard let service = IOServiceMatching("AppleSMC") else { return }
            var iterator: io_iterator_t = 0
            guard IOServiceGetMatchingServices(kIOMainPortDefault, service, &iterator) == KERN_SUCCESS else { return }
            defer { IOObjectRelease(iterator) }

            let device = IOIteratorNext(iterator)
            guard device != 0 else { return }
            defer { IOObjectRelease(device) }

            var conn: io_connect_t = 0
            let result = IOServiceOpen(device, mach_task_self_, 0, &conn)
            if result == KERN_SUCCESS {
                connection = conn
                isOpen = true
            }
        }

        deinit {
            if isOpen {
                IOServiceClose(connection)
            }
        }

        // MARK: - SMC structs matching kernel layout

        // SMC kernel function selectors
        private static let kSMCHandleYPCEvent: UInt32 = 2
        private static let kSMCReadKey: UInt8 = 5
        private static let kSMCWriteKey: UInt8 = 6
        private static let kSMCGetKeyInfo: UInt8 = 9

        private struct SMCVersion {
            var major: CUnsignedChar = 0
            var minor: CUnsignedChar = 0
            var build: CUnsignedChar = 0
            var reserved: CUnsignedChar = 0
            var release: CUnsignedShort = 0
        }

        private struct SMCPLimitData {
            var version: UInt16 = 0
            var length: UInt16 = 0
            var cpuPLimit: UInt32 = 0
            var gpuPLimit: UInt32 = 0
            var memPLimit: UInt32 = 0
        }

        private struct SMCKeyInfoData {
            var dataSize: UInt32 = 0
            var dataType: UInt32 = 0
            var dataAttributes: UInt8 = 0
        }

        private struct SMCParamStruct {
            var key: UInt32 = 0
            var vers: SMCVersion = SMCVersion()
            var pLimitData: SMCPLimitData = SMCPLimitData()
            var keyInfo: SMCKeyInfoData = SMCKeyInfoData()
            var padding: UInt16 = 0
            var result: UInt8 = 0
            var status: UInt8 = 0
            var data8: UInt8 = 0
            var data32: UInt32 = 0
            var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
                       (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        }

        func readKey(_ key: UInt32) -> SMCReadResult? {
            lock.lock()
            defer { lock.unlock() }
            guard isOpen else { return nil }

            // Step 1: get key info (data type + size)
            var inStruct = SMCParamStruct()
            inStruct.key = key
            inStruct.data8 = Connection.kSMCGetKeyInfo

            var outStruct = SMCParamStruct()
            guard callSMC(&inStruct, output: &outStruct) else { return nil }

            let dataType = outStruct.keyInfo.dataType
            let dataSize = outStruct.keyInfo.dataSize

            // Step 2: read the value
            inStruct = SMCParamStruct()
            inStruct.key = key
            inStruct.keyInfo.dataSize = dataSize
            inStruct.data8 = Connection.kSMCReadKey

            outStruct = SMCParamStruct()
            guard callSMC(&inStruct, output: &outStruct) else { return nil }

            // Extract bytes from tuple
            let count = Int(dataSize)
            var bytes = [UInt8](repeating: 0, count: count)
            withUnsafeBytes(of: outStruct.bytes) { buf in
                for i in 0..<min(count, buf.count) {
                    bytes[i] = buf[i]
                }
            }

            return SMCReadResult(dataType: dataType, dataSize: dataSize, bytes: bytes)
        }

        func writeKey(_ key: UInt32, dataType: UInt32, bytes: [UInt8]) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            guard isOpen else { return false }

            var inStruct = SMCParamStruct()
            inStruct.key = key
            inStruct.data8 = Connection.kSMCWriteKey
            inStruct.keyInfo.dataSize = UInt32(bytes.count)
            inStruct.keyInfo.dataType = dataType

            withUnsafeMutableBytes(of: &inStruct.bytes) { buf in
                for i in 0..<min(bytes.count, buf.count) {
                    buf[i] = bytes[i]
                }
            }

            var outStruct = SMCParamStruct()
            return callSMC(&inStruct, output: &outStruct)
        }

        private func callSMC(_ input: inout SMCParamStruct, output: inout SMCParamStruct) -> Bool {
            let inputSize = MemoryLayout<SMCParamStruct>.stride
            var outputSize = MemoryLayout<SMCParamStruct>.stride

            let result = IOConnectCallStructMethod(
                connection,
                Connection.kSMCHandleYPCEvent,
                &input,
                inputSize,
                &output,
                &outputSize
            )

            return result == KERN_SUCCESS && output.result == 0
        }
    }
}
