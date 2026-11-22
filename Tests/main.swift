import Foundation

let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
defer { try? FileManager.default.removeItem(at: root) }
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
let ledger = WaterLedger(root: root, calendar: calendar)
let beforeMidnight = ISO8601DateFormatter().date(from: "2026-11-22T22:59:00Z")!
let afterMidnight = ISO8601DateFormatter().date(from: "2026-11-22T23:01:00Z")!
func expect(_ condition: @autoclosure () throws -> Bool, _ name: String) throws {
    guard try condition() else { fatalError("FAIL: \(name)") }
    print("PASS: \(name)")
}
try expect(ledger.count(on: beforeMidnight) == 0, "Empty day starts at zero")
try ledger.record(1, at: beforeMidnight)
try ledger.record(1, at: beforeMidnight)
try expect(ledger.count(on: beforeMidnight) == 2, "Two taps record one liter")
try ledger.record(-1, at: beforeMidnight)
try expect(ledger.count(on: beforeMidnight) == 1, "Subtract half a liter")
try expect(WaterLedger(root: root, calendar: calendar).count(on: beforeMidnight) == 1, "Counter survives reopening")
try expect(ledger.count(on: afterMidnight) == 0, "New local day starts at zero")
try ledger.record(-1, at: afterMidnight)
try expect(ledger.count(on: afterMidnight) == 0, "Counter cannot go below zero")
DispatchQueue.concurrentPerform(iterations: 30) { _ in
    do { try ledger.record(1, at: afterMidnight) } catch { fatalError("Concurrent write failed: \(error)") }
}
try expect(ledger.count(on: afterMidnight) == 30, "Concurrent app and widget writes preserve every tap")
try expect(ledger.count(on: beforeMidnight) == 1, "Previous day stays intact")
print("All water ledger tests passed.")
