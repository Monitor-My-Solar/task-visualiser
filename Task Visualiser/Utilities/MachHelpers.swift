import Darwin

enum MachHelpers {

    struct CPULoadInfo {
        var userTicks: UInt32
        var systemTicks: UInt32
        var idleTicks: UInt32
        var niceTicks: UInt32
    }

    static func hostCPULoadInfo() -> CPULoadInfo? {
        var size = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let hostPort = mach_host_self()
        var loadInfo = host_cpu_load_info_data_t()

        let result = withUnsafeMutablePointer(to: &loadInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPtr in
                host_statistics(hostPort, HOST_CPU_LOAD_INFO, intPtr, &size)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        return CPULoadInfo(
            userTicks: loadInfo.cpu_ticks.0,
            systemTicks: loadInfo.cpu_ticks.1,
            idleTicks: loadInfo.cpu_ticks.2,
            niceTicks: loadInfo.cpu_ticks.3
        )
    }

    struct PerCoreCPUTicks {
        var user: UInt32
        var system: UInt32
        var idle: UInt32
        var nice: UInt32
    }

    static func perCoreCPULoadInfo() -> [PerCoreCPUTicks]? {
        let hostPort = mach_host_self()
        var processorCount: natural_t = 0
        var processorInfo: processor_info_array_t?
        var processorInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            hostPort,
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &processorInfo,
            &processorInfoCount
        )

        guard result == KERN_SUCCESS, let info = processorInfo else { return nil }

        var cores: [PerCoreCPUTicks] = []
        let cpuLoadInfoSize = Int32(CPU_STATE_MAX)

        for i in 0..<Int(processorCount) {
            let offset = i * Int(cpuLoadInfoSize)
            let user = UInt32(bitPattern: info[offset + Int(CPU_STATE_USER)])
            let system = UInt32(bitPattern: info[offset + Int(CPU_STATE_SYSTEM)])
            let idle = UInt32(bitPattern: info[offset + Int(CPU_STATE_IDLE)])
            let nice = UInt32(bitPattern: info[offset + Int(CPU_STATE_NICE)])
            cores.append(PerCoreCPUTicks(user: user, system: system, idle: idle, nice: nice))
        }

        let deallocSize = vm_size_t(
            Int(processorInfoCount) * MemoryLayout<integer_t>.stride
        )
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), deallocSize)

        return cores
    }
}
