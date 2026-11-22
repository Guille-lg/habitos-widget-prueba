import Foundation

/// Each tap is one immutable file. App and widget can write concurrently without
/// overwriting each other's counts. Records stay on the device, in the App Group.
struct WaterLedger {
    let root: URL
    var calendar: Calendar = .current

    struct Event: Codable {
        let id: UUID
        let timestamp: Date
        let halfLiters: Int
    }

    func dayKey(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    private func directory(for date: Date) -> URL {
        root.appendingPathComponent("water-events", isDirectory: true)
            .appendingPathComponent(dayKey(for: date), isDirectory: true)
    }

    func count(on date: Date = Date()) throws -> Int {
        let folder = directory(for: date)
        guard FileManager.default.fileExists(atPath: folder.path) else { return 0 }
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        let decoder = JSONDecoder()
        let total = try files.filter { $0.pathExtension == "json" }.reduce(0) { total, file in
            total + (try decoder.decode(Event.self, from: Data(contentsOf: file))).halfLiters
        }
        return max(0, total)
    }

    @discardableResult
    func record(_ halfLiters: Int, at date: Date = Date()) throws -> Int {
        guard halfLiters == 1 || halfLiters == -1 else { throw LedgerError.invalidAmount }
        if halfLiters < 0 && (try count(on: date)) == 0 { return 0 }
        let event = Event(id: UUID(), timestamp: date, halfLiters: halfLiters)
        let folder = directory(for: date)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent(event.id.uuidString).appendingPathExtension("json")
        try JSONEncoder().encode(event).write(to: file, options: .atomic)
        return try count(on: date)
    }
}

enum LedgerError: LocalizedError {
    case sharedStorageUnavailable, invalidAmount
    var errorDescription: String? {
        switch self {
        case .sharedStorageUnavailable:
            return "No se ha podido compartir el registro con el widget. Reinstala la prueba conservando su extensión."
        case .invalidAmount: return "Cantidad no válida."
        }
    }
}
