import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Almacenamiento sincronizado con toda la app
    @AppStorage("accentColor") var accentColorHex: String = "FF7F50" // Naranja por defecto
    @AppStorage("appBackgroundMode") var appBackgroundMode: String = "black" // "black" o "white"
    
    // Lista de colores disponibles para el tema
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
                // Sección de Identidad de la App
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: accentColorHex))
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

                // Sección de Apariencia, Tema y Fondo
                Section(header: Text("Apariencia y Tema de Color")) {
                    
                    // Selector de Color de Tema
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(themeColors, id: \.hex) { colorItem in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: colorItem.hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: accentColorHex == colorItem.hex ? 3 : 0)
                                        )
                                        .shadow(radius: 2)
                                        .onTapGesture {
                                            // Actualiza el color del tema globalmente al instante
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
                    
                    // Selector de Fondo: Blanco o Negro
                    Picker("Fondo de la App", selection: $appBackgroundMode) {
                        Text("Negro (Dark)").tag("black")
                        Text("Blanco (Light)").tag("white")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                // Sección de Información del Dispositivo
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
