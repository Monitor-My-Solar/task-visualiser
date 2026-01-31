import SwiftUI

struct ProcessDetailPopover: View {
    let process: ProcessEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = process.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading) {
                    Text(process.name)
                        .font(.headline)
                    Text("PID: \(process.pid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            LabeledContent("CPU Usage", value: process.formattedCPU)
            LabeledContent("Memory", value: process.formattedMemory)
            LabeledContent("User", value: process.user)
            LabeledContent("Status", value: process.isActive ? "Active" : "Inactive")
        }
        .padding()
        .frame(width: 250)
    }
}
