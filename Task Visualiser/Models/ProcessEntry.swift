import Foundation
import AppKit

struct ProcessEntry: Identifiable, Sendable {
    let id: pid_t
    let name: String
    let bundleIdentifier: String?
    let cpuUsage: Double
    let memoryBytes: UInt64
    let user: String
    let isActive: Bool
    let icon: NSImage?

    var pid: pid_t { id }

    var formattedMemory: String {
        memoryBytes.formattedByteCount
    }

    var formattedCPU: String {
        cpuUsage.formattedPercentage
    }
}
