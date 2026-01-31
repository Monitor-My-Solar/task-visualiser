import SwiftUI

struct ProcessListView: View {
    @Bindable var viewModel: ProcessListViewModel
    @Environment(PinnedProcessService.self) private var pinnedService

    var body: some View {
        VStack(spacing: 0) {
            ProcessToolbar(viewModel: viewModel)

            Table(viewModel.filteredProcesses, selection: $viewModel.selectedPID, sortOrder: $viewModel.sortOrder) {
                TableColumn("Name", value: \.name) { process in
                    HStack(spacing: 6) {
                        if let icon = process.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "app")
                                .frame(width: 16, height: 16)
                        }
                        Text(process.name)
                            .lineLimit(1)
                    }
                }
                .width(min: 150, ideal: 250)

                TableColumn("PID", value: \.id) { process in
                    Text("\(process.pid)")
                        .monospacedDigit()
                }
                .width(60)

                TableColumn("CPU", value: \.cpuUsage) { process in
                    Text(process.formattedCPU)
                        .monospacedDigit()
                }
                .width(70)

                TableColumn("Memory", value: \.memoryBytes) { process in
                    Text(process.formattedMemory)
                        .monospacedDigit()
                }
                .width(80)

                TableColumn("User", value: \.user) { process in
                    Text(process.user)
                        .lineLimit(1)
                }
                .width(80)
            }
            .contextMenu(forSelectionType: pid_t.self) { pids in
                if let pid = pids.first,
                   let process = viewModel.processes.first(where: { $0.pid == pid }) {
                    let identifier = process.bundleIdentifier ?? process.name
                    if pinnedService.isPinned(identifier: identifier) {
                        Button("Unpin from Dashboard") {
                            pinnedService.unpin(identifier: identifier)
                        }
                    } else {
                        Button("Pin to Dashboard") {
                            pinnedService.pin(identifier: identifier, displayName: process.name)
                        }
                    }
                }
            }

            if let process = viewModel.selectedProcess {
                Divider()
                ProcessDetailChartView(
                    process: process,
                    history: viewModel.selectedProcessHistory
                )
                .frame(height: 220)
                .background(.background.secondary)
            }
        }
        .navigationTitle("Processes")
        .task {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
}
