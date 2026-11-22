import AppIntents
import WidgetKit

struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Añadir medio litro de agua"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        try SharedStorage.ledger().record(1)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStorage.widgetKind)
        return .result()
    }
}
