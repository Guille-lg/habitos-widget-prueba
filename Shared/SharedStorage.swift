import Foundation

enum SharedStorage {
    static let originalGroup = "group.org.habitlab.watertrial"
    static let widgetKind = "WaterTrialWidget"

    static func ledger() throws -> WaterLedger {
        for group in groupCandidates() {
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
                return WaterLedger(root: url)
            }
        }
        // Never silently fall back to app-private defaults: that would make the
        // app look functional while the widget reads a different counter.
        throw LedgerError.sharedStorageUnavailable
    }

    static func groupCandidates() -> [String] {
        // SideStore can rename App Groups when signing. Read the actual signed
        // entitlements from this executable instead of assuming the build ID.
        var groups = signedGroups()
        groups += Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] ?? []
        groups.append(originalGroup)
        var seen = Set<String>()
        return groups.filter { seen.insert($0).inserted }
    }

    private static func signedGroups() -> [String] {
        guard let executable = Bundle.main.executableURL,
              let data = try? Data(contentsOf: executable, options: .mappedIfSafe) else { return [] }
        func word(_ offset: Int, big: Bool = false) -> UInt32? {
            guard offset >= 0, offset <= data.count - 4 else { return nil }
            let bytes = (0..<4).map { UInt32(data[offset + $0]) }
            return big ? (bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3])
                       : (bytes[3] << 24 | bytes[2] << 16 | bytes[1] << 8 | bytes[0])
        }
        // arm64 device binaries are thin MH_MAGIC_64 Mach-O images.
        guard word(0) == 0xfeedfacf, let commands = word(16), commands < 8192 else { return [] }
        var offset = 32
        for _ in 0..<commands {
            guard let command = word(offset), let size = word(offset + 4), size >= 8,
                  offset + Int(size) <= data.count else { return [] }
            if command == 0x1d, let signatureOffset = word(offset + 8), let signatureSize = word(offset + 12) {
                let base = Int(signatureOffset), limit = base + Int(signatureSize)
                guard limit <= data.count, word(base, big: true) == 0xfade0cc0,
                      let count = word(base + 8, big: true), count < 1024 else { return [] }
                for i in 0..<Int(count) {
                    guard let type = word(base + 12 + i * 8, big: true),
                          let relative = word(base + 16 + i * 8, big: true), type == 5 else { continue }
                    let start = base + Int(relative)
                    guard word(start, big: true) == 0xfade7171,
                          let length = word(start + 4, big: true), length >= 8,
                          start + Int(length) <= limit else { continue }
                    let xml = data.subdata(in: (start + 8)..<(start + Int(length)))
                    guard let plist = try? PropertyListSerialization.propertyList(from: xml, format: nil) as? [String: Any] else { continue }
                    return plist["com.apple.security.application-groups"] as? [String] ?? []
                }
            }
            offset += Int(size)
        }
        return []
    }
}
