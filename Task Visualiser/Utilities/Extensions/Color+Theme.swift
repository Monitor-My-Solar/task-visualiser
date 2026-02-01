import SwiftUI

extension Color {
    static let cpuColor = Color.blue
    static let cpuUserColor = Color.blue
    static let cpuSystemColor = Color.blue.opacity(0.6)

    static let memoryColor = Color.green
    static let memoryActiveColor = Color.green
    static let memoryWiredColor = Color.green.opacity(0.7)
    static let memoryCompressedColor = Color.yellow
    static let memoryInactiveColor = Color.green.opacity(0.3)

    static let networkColor = Color.purple
    static let networkInColor = Color.purple
    static let networkOutColor = Color.pink

    static let diskColor = Color.orange
    static let diskReadColor = Color.orange
    static let diskWriteColor = Color.red

    static let batteryColor = Color.yellow
    static let batteryChargingColor = Color.green

    static let gpuColor = Color.teal

    static let thermalColor = Color.red
    static let fanColor = Color.cyan
    static let powerColor = Color.orange
}

extension ShapeStyle where Self == Color {
    static var cpuColor: Color { .blue }
    static var cpuUserColor: Color { .blue }
    static var cpuSystemColor: Color { .blue.opacity(0.6) }

    static var memoryColor: Color { .green }
    static var memoryActiveColor: Color { .green }
    static var memoryWiredColor: Color { .green.opacity(0.7) }
    static var memoryCompressedColor: Color { .yellow }
    static var memoryInactiveColor: Color { .green.opacity(0.3) }

    static var networkColor: Color { .purple }
    static var networkInColor: Color { .purple }
    static var networkOutColor: Color { .pink }

    static var diskColor: Color { .orange }
    static var diskReadColor: Color { .orange }
    static var diskWriteColor: Color { .red }

    static var batteryColor: Color { .yellow }
    static var batteryChargingColor: Color { .green }

    static var gpuColor: Color { .teal }

    static var thermalColor: Color { .red }
    static var fanColor: Color { .cyan }
    static var powerColor: Color { .orange }
}
