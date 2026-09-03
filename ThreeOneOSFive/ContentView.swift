import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showLogs = false

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
                        PatchProjectsView()
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(Color(hexString: accentColorHex))
                            .toolbar {
                                toolbarContent
                            }
                    }
                case 1:
                    NavigationStack {
                        LibraryDownloadView(accentColorHex: $accentColorHex)
                            .navigationTitle("Librería")
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
                    NavigationStack {
                        PatchProjectsView()
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(Color(hexString: accentColorHex))
                    }
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

private enum LibraryTabType {
    case aim, visual
}

// Vista de Librería con selector AIM / VISUAL interno
struct LibraryDownloadView: View {
    @State private var selectedLibraryTab: LibraryTabType = .aim
    @State private var alertMessage = ""
    @State private var showAlert = false
    @Binding var accentColorHex: String

    var body: some View {
        VStack(spacing: 0) {
            // Selector de pestañas AIM / VISUAL dentro de la librería
            HStack(spacing: 12) {
                Button(action: { selectedLibraryTab = .aim }) {
                    Text("AIM")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedLibraryTab == .aim ? Color(hexString: accentColorHex) : Color(.systemGray6))
                        .foregroundColor(selectedLibraryTab == .aim ? .white : .secondary)
                        .cornerRadius(12)
                }

                Button(action: { selectedLibraryTab = .visual }) {
                    Text("VISUAL")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedLibraryTab == .visual ? Color(hexString: accentColorHex) : Color(.systemGray6))
                        .foregroundColor(selectedLibraryTab == .visual ? .white : .secondary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            List {
                if selectedLibraryTab == .aim {
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
                } else {
                    Section(header: Text("Opciones Visuales")) {
                        VisualDownloadRow(title: "Holo Armas Celeste", description: "Efecto holográfico celeste para armas.", icon: "sparkles", color: .cyan, accentColorHex: $accentColorHex) {
                            downloadAndSavePatch(fileName: "HoloCeleste.3105", displayName: "Holo Armas Celeste")
                        }
                        
                        VisualDownloadRow(title: "Holo Armas Amarillo", description: "Efecto holográfico amarillo para armas.", icon: "sparkles", color: .yellow, accentColorHex: $accentColorHex) {
                            downloadAndSavePatch(fileName: "HoloAmarillo.3105", displayName: "Holo Armas Amarillo")
                        }
                        
                        VisualDownloadRow(title: "Holo Armas Verde", description: "Efecto holográfico verde para armas.", icon: "sparkles", color: .green, accentColorHex: $accentColorHex) {
                            downloadAndSavePatch(fileName: "HoloVerde.3105", displayName: "Holo Armas Verde")
                        }
                    }
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

private struct VisualDownloadRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var accentColorHex: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
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
