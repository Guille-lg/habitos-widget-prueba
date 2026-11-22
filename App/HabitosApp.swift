import SwiftUI
import WidgetKit

@main
struct HabitosApp: App {
    var body: some Scene {
        WindowGroup { WaterView().preferredColorScheme(.light) }
    }
}

struct WaterView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var count = 0
    @State private var error: String?
    @State private var showInstructions = false

    var liters: String { (Double(count) / 2).formatted(.number.locale(Locale(identifier: "es_ES"))) }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Label("Agua", systemImage: "drop.fill").font(.title2.bold())
                    Spacer()
                    Text(Date(), format: .dateTime.day().month(.abbreviated))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 16) {
                    (Text(liters).font(.system(size: 76, weight: .bold)) +
                     Text(" / 3 L").font(.title2).foregroundColor(.secondary))
                        .accessibilityLabel("\(liters) de 3 litros hoy")
                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(index < count ? Color.black : Color.black.opacity(0.08))
                                .frame(height: 10)
                        }
                    }.accessibilityHidden(true)
                }
                if let error {
                    Text(error).font(.subheadline).foregroundStyle(.red)
                        .accessibilityIdentifier("storage-error")
                }
                Button { record(1) } label: {
                    Label("0,5 L", systemImage: "plus")
                        .font(.title3.bold()).frame(maxWidth: .infinity).padding(.vertical, 18)
                }
                .buttonStyle(.plain).foregroundStyle(.white).background(.black, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Añadir medio litro").accessibilityIdentifier("add-water")
                Button { record(-1) } label: {
                    Label("Restar 0,5 L", systemImage: "minus").frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.plain).foregroundStyle(.secondary).disabled(count == 0)
                Spacer()
                Button("Añadir el widget") { showInstructions = true }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
            }
            .padding(24)
            .navigationTitle("Hábitos")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: refresh)
            .onChange(of: scenePhase) { _, phase in if phase == .active { refresh() } }
            .sheet(isPresented: $showInstructions) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("1. Mantén pulsado un espacio vacío en la pantalla de inicio.")
                        Text("2. Pulsa Editar y Añadir widget.")
                        Text("3. Busca Hábitos y añade el widget Agua.")
                        Text("Pulsa +0,5 L en el widget. El contador debe cambiar sin abrir la app.")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(24).navigationTitle("Añadir el widget").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { showInstructions = false } } }
                }.presentationDetents([.medium, .large])
            }
        }.tint(.black)
    }

    private func refresh() {
        do { count = try SharedStorage.ledger().count(); error = nil }
        catch { self.error = error.localizedDescription }
    }
    private func record(_ delta: Int) {
        do {
            count = try SharedStorage.ledger().record(delta)
            error = nil
            WidgetCenter.shared.reloadTimelines(ofKind: SharedStorage.widgetKind)
        } catch { self.error = error.localizedDescription }
    }
}
