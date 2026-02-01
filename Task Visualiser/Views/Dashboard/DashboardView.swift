import SwiftUI

struct DashboardView: View {
    let viewModel: DashboardViewModel
    @Environment(PinnedProcessService.self) private var pinnedService

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                CPUSummaryWidget(
                    usage: viewModel.stats.cpu.totalUsage,
                    sparkline: viewModel.cpuHistory
                )

                MemorySummaryWidget(
                    memory: viewModel.stats.memory,
                    sparkline: viewModel.memoryHistory
                )

                NetworkSummaryWidget(
                    network: viewModel.stats.network,
                    inSparkline: viewModel.networkInHistory,
                    outSparkline: viewModel.networkOutHistory
                )

                DiskSummaryWidget(
                    disk: viewModel.stats.disk,
                    readSparkline: viewModel.diskReadHistory,
                    writeSparkline: viewModel.diskWriteHistory
                )

                GPUSummaryWidget(
                    usage: viewModel.stats.gpu.utilization,
                    sparkline: viewModel.gpuHistory,
                    vramUsed: viewModel.stats.gpu.devices.first?.vramUsed
                )

                BatterySummaryWidget(
                    battery: viewModel.stats.battery,
                    sparkline: viewModel.batteryLevelHistory
                )

                ThermalSummaryWidget(
                    thermal: viewModel.stats.thermal,
                    cpuTempSparkline: viewModel.thermalTempHistory,
                    powerSparkline: viewModel.thermalPowerHistory
                )

                ForEach(pinnedService.pinnedProcesses) { pinned in
                    PinnedProcessWidget(
                        pinned: pinned,
                        data: pinnedService.liveData[pinned.identifier],
                        onUnpin: { pinnedService.unpin(identifier: pinned.identifier) }
                    )
                }

                SystemInfoWidget()
                    .gridCellColumns(2)
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .task {
            while !Task.isCancelled {
                await viewModel.refreshHistory()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
