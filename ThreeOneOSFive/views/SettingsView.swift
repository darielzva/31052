import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Almacenamiento sincronizado con toda la app
    @AppStorage("accentColor") var accentColorHex: String = "FF7F50"
    @AppStorage("appBackgroundMode") var appBackgroundMode: String = "black"
    
    let themeColors: [(name: String, hex: String)] = [
        ("Púrpura", "AF52DE"),
        ("Azul", "007AFF"),
        ("Verde", "34C759"),
        ("Naranja", "FF7F50"),
        ("Rojo", "FF3B30")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.accent)
                        VStack(alignment: .leading) {
                            Text("3105")
                                .font(.headline)
                            Text("Version 1.1.1")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Apariencia y Tema de Color")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(themeColors, id: \.hex) { colorItem in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(AppTheme.accent)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: accentColorHex == colorItem.hex ? 3 : 0)
                                        )
                                        .shadow(radius: 2)
                                        .onTapGesture {
                                            accentColorHex = colorItem.hex
                                        }
                                    
                                    Text(colorItem.name)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Picker("Fondo de la App", selection: $appBackgroundMode) {
                        Text("Negro (Dark)").tag("black")
                        Text("Blanco (Light)").tag("white")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                Section(header: Text("Device")) {
                    LabeledContent("Hardware model") {
                        Text(AppInfo.displayMachineName)
                            .font(.body.monospaced())
                    }
                    LabeledContent("iOS Version") {
                        Text("\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                            .font(.body.monospaced())
                    }
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
