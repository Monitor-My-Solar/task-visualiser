import SwiftUI

struct ProcessToolbar: View {
    @Bindable var viewModel: ProcessListViewModel
    @State private var showKillConfirmation = false
    @State private var showForceKillConfirmation = false
    @State private var showTerminateFailedAlert = false

    private var isSandboxed: Bool {
        SandboxDetector.isSandboxed
    }

    var body: some View {
        HStack {
            TextField("Search processes...", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 250)

            Spacer()

            Text("\(viewModel.filteredProcesses.count) processes")
                .foregroundStyle(.secondary)
                .font(.caption)

            Button("Quit") {
                showKillConfirmation = true
            }
            .disabled(viewModel.selectedPID == nil)
            .confirmationDialog("Quit this process?", isPresented: $showKillConfirmation) {
                Button("Quit", role: .destructive) {
                    if !viewModel.terminateSelected() {
                        showTerminateFailedAlert = true
                    }
                }
            }

            Button("Force Quit") {
                showForceKillConfirmation = true
            }
            .disabled(viewModel.selectedPID == nil || isSandboxed)
            .help(isSandboxed ? "Force quit is unavailable in sandboxed mode" : "Force quit the selected process")
            .confirmationDialog("Force quit this process? Unsaved data may be lost.", isPresented: $showForceKillConfirmation) {
                Button("Force Quit", role: .destructive) {
                    if !viewModel.forceTerminateSelected() {
                        showTerminateFailedAlert = true
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .alert("Cannot Terminate Process", isPresented: $showTerminateFailedAlert) {
            Button("OK") {}
        } message: {
            if isSandboxed {
                Text("The App Sandbox prevents terminating other processes. Use the unsandboxed build for full process control.")
            } else {
                Text("The process could not be terminated. It may be a system process or owned by another user.")
            }
        }
    }
}
