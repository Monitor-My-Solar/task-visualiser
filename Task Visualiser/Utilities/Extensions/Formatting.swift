import Foundation

extension Double {
    var formattedPercentage: String {
        String(format: "%.1f%%", self)
    }

    var formattedTemperature: String {
        String(format: "%.1f\u{00B0}C", self)
    }

    var formattedWatts: String {
        String(format: "%.1f W", self)
    }

    var formattedRPM: String {
        String(format: "%.0f RPM", self)
    }
}

extension UInt64 {
    var formattedByteCount: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .memory)
    }
}

extension Int64 {
    var formattedByteCount: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .memory)
    }
}

enum ByteRateFormatter {
    static func string(bytesPerSecond: Double) -> String {
        let absValue = abs(bytesPerSecond)
        if absValue < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if absValue < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else if absValue < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        } else {
            return String(format: "%.2f GB/s", bytesPerSecond / (1024 * 1024 * 1024))
        }
    }
}
