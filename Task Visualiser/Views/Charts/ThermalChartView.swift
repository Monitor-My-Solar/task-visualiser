import SwiftUI
import Charts

struct ThermalChartView: View {
    let viewModel: ThermalViewModel
    @State private var fanTargets: [Int: Double] = [:]

    private var isSandboxed: Bool {
        !SMCHelpers.isAvailable
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !viewModel.thermal.hasData && isSandboxed {
                    unavailableSection
                } else {
                    if !viewModel.thermal.fans.isEmpty {
                        fansSection
                    }
                    if !viewModel.thermal.temperatures.isEmpty {
                        temperaturesSection
                    }
                    if viewModel.thermal.systemPowerWatts != nil ||
                       viewModel.thermal.cpuPowerWatts != nil ||
                       viewModel.thermal.gpuPowerWatts != nil {
                        powerSection
                    }
                    if !isSandboxed && !viewModel.thermal.fans.isEmpty {
                        fanControlSection
                    }
                    temperatureHistorySection
                    if !viewModel.thermal.fans.isEmpty {
                        fanHistorySection
                    }
                    if !viewModel.powerHistory.isEmpty {
                        powerHistorySection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Thermal")
        .task {
            await viewModel.refreshHistory()
        }
    }

    // MARK: - Fans

    private var fansSection: some View {
        GroupBox("Fans") {
            HStack(spacing: 40) {
                ForEach(viewModel.thermal.fans) { fan in
                    VStack(spacing: 8) {
                        GaugeView(
                            value: fan.percentOfMax,
                            total: 100,
                            label: "Fan \(fan.id + 1)",
                            color: .fanColor,
                            lineWidth: 10
                        )
                        .frame(width: 100, height: 120)

                        Text(fan.currentRPM.formattedRPM)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .monospacedDigit()

                        Text(fan.mode.rawValue)
                            .font(.caption2)
                            .foregroundStyle(fan.mode == .forced ? .orange : .secondary)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Temperatures

    private var temperaturesSection: some View {
        GroupBox("Temperatures") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.thermal.temperatures) { reading in
                    HStack {
                        Circle()
                            .fill(temperatureColor(reading.celsius))
                            .frame(width: 8, height: 8)
                        Text(reading.label)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(reading.celsius.formattedTemperature)
                            .monospacedDigit()
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Power

    private var powerSection: some View {
        GroupBox("Power Draw") {
            HStack(spacing: 40) {
                if let system = viewModel.thermal.systemPowerWatts {
                    VStack(spacing: 4) {
                        Text(system.formattedWatts)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.powerColor)
                        Text("System Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let cpu = viewModel.thermal.cpuPowerWatts {
                    VStack(spacing: 4) {
                        Text(cpu.formattedWatts)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.cpuColor)
                        Text("CPU")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let gpu = viewModel.thermal.gpuPowerWatts {
                    VStack(spacing: 4) {
                        Text(gpu.formattedWatts)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.gpuColor)
                        Text("GPU")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Fan Control

    private var fanControlSection: some View {
        GroupBox("Fan Control") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.thermal.fans) { fan in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Fan \(fan.id + 1)")
                                .font(.headline)
                            Spacer()
                            Text(fan.mode.rawValue)
                                .font(.caption)
                                .foregroundStyle(fan.mode == .forced ? .orange : .secondary)
                        }

                        HStack {
                            Text(fan.minRPM.formattedRPM)
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Slider(
                                value: Binding(
                                    get: { fanTargets[fan.id] ?? fan.targetRPM },
                                    set: { fanTargets[fan.id] = $0 }
                                ),
                                in: fan.minRPM...max(fan.maxRPM, fan.minRPM + 1)
                            )
                            .onChange(of: fanTargets[fan.id]) { _, newValue in
                                if let rpm = newValue {
                                    viewModel.setFanSpeed(fanIndex: fan.id, targetRPM: rpm)
                                }
                            }

                            Text(fan.maxRPM.formattedRPM)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Target: \((fanTargets[fan.id] ?? fan.targetRPM).formattedRPM)")
                                .font(.caption)
                                .monospacedDigit()

                            Spacer()

                            Button("Auto") {
                                fanTargets[fan.id] = nil
                                viewModel.restoreFanAuto(fanIndex: fan.id)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                Divider()

                Button("Restore All Fans to Auto") {
                    fanTargets.removeAll()
                    viewModel.restoreAllFansAuto()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    // MARK: - History: Temperature

    private var temperatureHistorySection: some View {
        GroupBox("Temperature History") {
            if viewModel.cpuTempHistory.isEmpty && viewModel.gpuTempHistory.isEmpty {
                Text("Collecting data\u{2026}")
                    .foregroundStyle(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(Array(viewModel.cpuTempHistory.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Sample", index),
                            y: .value("Temp", value),
                            series: .value("Sensor", "CPU")
                        )
                        .foregroundStyle(.thermalColor)
                        .interpolationMethod(.catmullRom)
                    }
                    ForEach(Array(viewModel.gpuTempHistory.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Sample", index),
                            y: .value("Temp", value),
                            series: .value("Sensor", "GPU")
                        )
                        .foregroundStyle(.gpuColor)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartForegroundStyleScale(["CPU": Color.thermalColor, "GPU": Color.gpuColor])
                .chartYAxisLabel("\u{00B0}C")
                .frame(height: 250)
                .padding()
            }
        }
    }

    // MARK: - History: Fan RPM

    private var fanHistorySection: some View {
        GroupBox("Fan RPM History") {
            if viewModel.fanRPMHistory.isEmpty || viewModel.fanRPMHistory.allSatisfy(\.isEmpty) {
                Text("Collecting data\u{2026}")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(Array(viewModel.fanRPMHistory.enumerated()), id: \.offset) { fanIdx, rpmValues in
                        ForEach(Array(rpmValues.enumerated()), id: \.offset) { sampleIdx, rpm in
                            LineMark(
                                x: .value("Sample", sampleIdx),
                                y: .value("RPM", rpm),
                                series: .value("Fan", "Fan \(fanIdx + 1)")
                            )
                            .foregroundStyle(.fanColor.opacity(1.0 - Double(fanIdx) * 0.3))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .chartYAxisLabel("RPM")
                .frame(height: 200)
                .padding()
            }
        }
    }

    // MARK: - History: Power

    private var powerHistorySection: some View {
        GroupBox("Power History") {
            Chart(Array(viewModel.powerHistory.enumerated()), id: \.offset) { index, value in
                AreaMark(
                    x: .value("Sample", index),
                    y: .value("Watts", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.powerColor.opacity(0.3), Color.powerColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Sample", index),
                    y: .value("Watts", value)
                )
                .foregroundStyle(.powerColor)
                .interpolationMethod(.catmullRom)
            }
            .chartYAxisLabel("Watts")
            .frame(height: 200)
            .padding()
        }
    }

    // MARK: - Unavailable

    private var unavailableSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("Thermal Monitoring Unavailable")
                    .font(.headline)
                Text("SMC access requires the unsandboxed build. Temperature sensors, fan speeds, and power draw are not available in sandboxed mode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func temperatureColor(_ celsius: Double) -> Color {
        if celsius >= 90 { return .red }
        if celsius >= 70 { return .orange }
        if celsius >= 50 { return .yellow }
        return .green
    }
}
