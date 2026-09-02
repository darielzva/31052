import SwiftUI
import UIKit

private enum PatchTabType {
    case aim, visual
}

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var selectedPatchTab: PatchTabType = .aim

    // Almacenamientos sincronizados
    @AppStorage("appBackgroundMode") var appBackgroundMode: String = "black"
    @AppStorage("accentColor") var accentColorHex: String = "FF7F50"

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fondo dinámico Blanco o Negro a pantalla completa
            Group {
                if appBackgroundMode == "black" {
                    Color.black.ignoresSafeArea()
                } else {
                    Color.white.ignoresSafeArea()
                }
            }

            // Contenedor principal de pestañas
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack {
                        VStack(spacing: 0) {
                            // Selector de pestañas estilo píldora (AIM / VISUAL)
                            HStack(spacing: 12) {
                                Button(action: { selectedPatchTab = .aim }) {
                                    Text("AIM")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedPatchTab == .aim ? Color(hexString: accentColorHex) : Color(.systemGray6))
                                        .foregroundColor(selectedPatchTab == .aim ? .white : .secondary)
                                        .cornerRadius(12)
                                }

                                Button(action: { selectedPatchTab = .visual }) {
                                    Text("VISUAL")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedPatchTab == .visual ? Color(hexString: accentColorHex) : Color(.systemGray6))
                                        .foregroundColor(selectedPatchTab == .visual ? .white : .secondary)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)

                            if selectedPatchTab == .aim {
                                PatchProjectsView()
                            } else {
                                List {
                                    Section {
                                        visualRow(title: "Holo Armas Celeste", icon: "sparkles", color: .cyan)
                                        visualRow(title: "Holo Armas Amarillo", icon: "sparkles", color: .yellow)
                                        visualRow(title: "Holo Armas Verde", icon: "sparkles", color: .green)
                                    }
                                }
                                .listStyle(.insetGrouped)
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .tint(Color(hexString: accentColorHex))
                        .toolbar {
                            toolbarContent
                        }
                    }
                case 1:
                    NavigationStack {
                        LibraryDownloadView(accentColorHex: $accentColorHex)
                            .navigationTitle("Librería de Aims")
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(Color(hexString: accentColorHex))
                            .toolbar {
                                toolbarContent
                            }
                    }
                case 2:
                    NavigationStack {
                        SettingsView()
                            .navigationTitle("Configuración")
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(Color(hexString: accentColorHex))
                    }
                default:
                    PatchProjectsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Barra de navegación flotante estilo pastilla personalizada
            HStack(spacing: 28) {
                FloatingTabButton(icon: "shippingbox.fill", title: "Parches", tag: 0, selectedTab: $selectedTab, accentColorHex: accentColorHex)
                FloatingTabButton(icon: "arrow.down.circle.fill", title: "Librería", tag: 1, selectedTab: $selectedTab, accentColorHex: accentColorHex)
                FloatingTabButton(icon: "gearshape.fill", title: "Ajustes", tag: 2, selectedTab: $selectedTab, accentColorHex: accentColorHex)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .cornerRadius(38)
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(Color(hexString: accentColorHex))
        .imageScale(.medium)
        .preferredColorScheme(appBackgroundMode == "black" ? .dark : .light)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
    }

    @ViewBuilder
    private func visualRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 6)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showLogs = true } label: {
                Image(systemName: "apple.terminal")
            }
            .accessibilityLabel(language.text("accessibility.open_logs"))
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(language.text("accessibility.open_settings"))
        }
    }
}

// Botón individual para la pastilla flotante con color dinámico
private struct FloatingTabButton: View {
    let icon: String
    let title: String
    let tag: Int
    @Binding var selectedTab: Int
    let accentColorHex: String

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tag
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                if selectedTab == tag {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, selectedTab == tag ? 18 : 12)
            .foregroundColor(selectedTab == tag ? .white : .gray)
            .background(selectedTab == tag ? Color(hexString: accentColorHex) : Color.clear)
            .cornerRadius(24)
        }
    }
}

// Vista de Librería de descargas actualizada para recibir el color dinámico
struct LibraryDownloadView: View {
    @State private var alertMessage = ""
    @State private var showAlert = false
    @Binding var accentColorHex: String

    var body: some View {
        List {
            Section(header: Text("Aims y Modificaciones")) {
                DownloadRow(title: "Aimbot Pecho", description: "Apunta automáticamente al torso del enemigo.", accentColorHex: $accentColorHex) {
                    downloadAndSavePatch(fileName: "AimbotPecho.3105", displayName: "Aimbot Pecho")
                }
                
                DownloadRow(title: "Aimbot Cuello", description: "Calibración de precisión directa al cuello.", accentColorHex: $accentColorHex) {
                    downloadAndSavePatch(fileName: "AimbotCuello.3105", displayName: "Aimbot Cuello")
                }
                
                DownloadRow(title: "Aimbot Drag", description: "Mejora la velocidad de arrastre de mira.", accentColorHex: $accentColorHex) {
                    downloadAndSavePatch(fileName: "AimbotDrag.3105", displayName: "Aimbot Drag")
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Descarga Exitosa"), message: Text(alertMessage), dismissButton: .default(Text("Entendido")))
        }
    }

    private func downloadAndSavePatch(fileName: String, displayName: String) {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let patchesDir = documentsPath.appendingPathComponent("Patches").appendingPathComponent(displayName)
        
        do {
            try fileManager.createDirectory(at: patchesDir, withIntermediateDirectories: true, attributes: nil)
            let targetFile = patchesDir.appendingPathComponent(fileName)
            
            if !fileManager.fileExists(atPath: targetFile.path) {
                let sampleData = "DATA_3105_PATCH".data(using: .utf8) ?? Data()
                try sampleData.write(to: targetFile)
            }
            
            alertMessage = "Archivo \(displayName) descargado con éxito, impórtalo en parches y ejecútalo."
            showAlert = true
        } catch {
            alertMessage = "Error al guardar el archivo."
            showAlert = true
        }
    }
}

private struct DownloadRow: View {
    let title: String
    let description: String
    @Binding var accentColorHex: String
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: action) {
                Text("Descargar")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hexString: accentColorHex))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
