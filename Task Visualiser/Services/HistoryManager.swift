import Foundation

actor HistoryManager<T: Sendable> {
    private var buffer: [T] = []
    private let maxCount: Int

    init(maxCount: Int = 600) {
        self.maxCount = maxCount
    }

    func append(_ value: T) {
        buffer.append(value)
        if buffer.count > maxCount {
            buffer.removeFirst(buffer.count - maxCount)
        }
    }

    func values() -> [T] {
        buffer
    }

    func latest() -> T? {
        buffer.last
    }

    func clear() {
        buffer.removeAll()
    }

    func updateMaxCount(_ newMax: Int) {
        if buffer.count > newMax {
            buffer.removeFirst(buffer.count - newMax)
        }
    }
}
