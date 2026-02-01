import SwiftUI

struct ThermalSummaryWidget: View {
    let thermal: ThermalUsage
    let cpuTempSparkline: [Double]
    let powerSparkline: [Double]

    var body: some View {
        if thermal.hasData {
            dataLayout
        } else {
            unavailableLayout
        }
    }

    private var dataLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer.medium")
                    .font(.title2)
                    .foregroundStyle(.thermalColor)
                Text("Thermal")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                if let cpuTemp = thermal.cpuTemperature {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cpuTemp.formattedTemperature)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.thermalColor)
                        Text("CPU Temp")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let gpuTemp = thermal.gpuTemperature {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gpuTemp.formattedTemperature)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.gpuColor)
                        Text("GPU Temp")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let power = thermal.systemPowerWatts {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(power.formattedWatts)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.powerColor)
                        Text("Power")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            if !thermal.fans.isEmpty {
                HStack(spacing: 12) {
                    ForEach(thermal.fans) { fan in
                        HStack(spacing: 4) {
                            Image(systemName: "fan")
                                .font(.caption)
                                .foregroundStyle(.fanColor)
                            Text(fan.currentRPM.formattedRPM)
                                .font(.caption)
                                .monospacedDigit()
                        }
                    }
                    Spacer()
                }
            }

            if !cpuTempSparkline.isEmpty {
                MiniSparklineView(values: cpuTempSparkline, color: .thermalColor)
                    .frame(height: 30)
            } else if !powerSparkline.isEmpty {
                MiniSparklineView(values: powerSparkline, color: .powerColor)
                    .frame(height: 30)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var unavailableLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer.medium")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Thermal")
                    .font(.headline)
                Spacer()
            }

            Text("Requires unsandboxed build")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
