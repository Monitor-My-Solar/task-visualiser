import WidgetKit
import SwiftUI

@main
struct TaskVisualiserWidgetBundle: WidgetBundle {
    var body: some Widget {
        SystemMetricWidget()
        #if os(iOS)
        SystemStatusControl()
        #endif
    }
}
