import Foundation
import Darwin

final class NetworkMonitor: Sendable {

    private let lock = NSLock()
    private let prevBytesIn = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
    private let prevBytesOut = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
    private let prevTimestamp = UnsafeMutablePointer<Date?>.allocate(capacity: 1)

    init() {
        prevBytesIn.initialize(to: 0)
        prevBytesOut.initialize(to: 0)
        prevTimestamp.initialize(to: nil)
    }

    deinit {
        prevBytesIn.deinitialize(count: 1)
        prevBytesIn.deallocate()
        prevBytesOut.deinitialize(count: 1)
        prevBytesOut.deallocate()
        prevTimestamp.deinitialize(count: 1)
        prevTimestamp.deallocate()
    }

    nonisolated func snapshot() -> NetworkUsage {
        let (totalIn, totalOut) = readNetworkCounters()

        lock.lock()
        let pIn = prevBytesIn.pointee
        let pOut = prevBytesOut.pointee
        let pTime = prevTimestamp.pointee
        prevBytesIn.pointee = totalIn
        prevBytesOut.pointee = totalOut
        let now = Date.now
        prevTimestamp.pointee = now
        lock.unlock()

        var inPerSec: Double = 0
        var outPerSec: Double = 0

        if let pTime {
            let elapsed = now.timeIntervalSince(pTime)
            if elapsed > 0 && pIn > 0 {
                inPerSec = Double(totalIn &- pIn) / elapsed
                outPerSec = Double(totalOut &- pOut) / elapsed
            }
        }

        return NetworkUsage(
            bytesIn: totalIn,
            bytesOut: totalOut,
            bytesInPerSecond: max(inPerSec, 0),
            bytesOutPerSecond: max(outPerSec, 0),
            timestamp: now
        )
    }

    private func readNetworkCounters() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: size_t = 0

        guard sysctl(&mib, UInt32(mib.count), nil, &len, nil, 0) == 0, len > 0 else {
            return (0, 0)
        }

        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        defer { buf.deallocate() }

        guard sysctl(&mib, UInt32(mib.count), buf, &len, nil, 0) == 0 else {
            return (0, 0)
        }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var ptr = buf

        while ptr < buf + len {
            let ifm = ptr.withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
            if Int32(ifm.ifm_type) == RTM_IFINFO2 {
                ptr.withMemoryRebound(to: if_msghdr2.self, capacity: 1) { ifm2Ptr in
                    totalIn += ifm2Ptr.pointee.ifm_data.ifi_ibytes
                    totalOut += ifm2Ptr.pointee.ifm_data.ifi_obytes
                }
            }
            ptr += Int(ifm.ifm_msglen)
        }

        return (totalIn, totalOut)
    }
}
