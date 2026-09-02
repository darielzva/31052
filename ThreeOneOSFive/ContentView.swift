import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showLogs = false

    // Almacenamiento local para alternar fondo entre blanco y negro
    @AppStorage("appBackgroundMode") var appBackgroundMode: String = "black"

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

            // Contenedor principal de pestañas utilizando ZStack para la barra flotante estilo pastilla
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack {
                        PatchProjectsView()
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(AppTheme.accent)
                            .toolbar {
                                toolbarContent
                            }
                    }
                case 1:
                    NavigationStack {
                        LibraryDownloadView()
                            .navigationTitle("Librería de Aims")
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(AppTheme.accent)
                            .toolbar {
                                toolbarContent
                            }
                    }
                case 2:
                    NavigationStack {
                        SettingsView()
                            .navigationTitle("Configuración")
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(AppTheme.accent)
                    }
                default:
                    PatchProjectsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Barra de navegación flotante estilo pastilla personalizada (Más grande y táctil)
            HStack(spacing: 28) {
                FloatingTabButton(icon: "shippingbox.fill", title: "Parches", tag: 0, selectedTab: $selectedTab)
                FloatingTabButton(icon: "arrow.down.circle.fill", title: "Librería", tag: 1, selectedTab: $selectedTab)
                FloatingTabButton(icon: "gearshape.fill", title: "Ajustes", tag: 2, selectedTab: $selectedTab)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14) // Altura aumentada para mayor área táctil
            .background(.ultraThinMaterial)
            .cornerRadius(38)
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(AppTheme.accent)
        .imageScale(.small)
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

// Botón individual para la pastilla flotante (Tamaño optimizado y más visible)
private struct FloatingTabButton: View {
    let icon: String
    let title: String
    let tag: Int
    @Binding var selectedTab: Int

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tag
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                
                if selectedTab == tag {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, selectedTab == tag ? 18 : 12)
            .foregroundColor(selectedTab == tag ? .white : .gray)
            .background(selectedTab == tag ? AppTheme.accent : Color.clear)
            .cornerRadius(24)
        }
    }
}

// Vista de Librería de descargas para los Aims y archivos con notificación simulada
struct LibraryDownloadView: View {
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        List {
            Section(header: Text("Aims y Modificaciones")) {
                DownloadRow(title: "Aimbot Pecho", description: "Apunta automáticamente al torso del enemigo.") {
                    downloadAndSavePatch(fileName: "AimbotPecho.3105", displayName: "Aimbot Pecho")
                }
                
                DownloadRow(title: "Aimbot Cuello", description: "Calibración de precisión directa al cuello.") {
                    downloadAndSavePatch(fileName: "AimbotCuello.3105", displayName: "Aimbot Cuello")
                }
                
                DownloadRow(title: "Aimbot Drag", description: "Mejora la velocidad de arrastre de mira.") {
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
                    .background(AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

private struct CompactTabLabel: View {
    let title: String
    let systemImage: String

    @ViewBuilder
    var body: some View {
        if let image = UIImage(
            systemName: systemImage,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        )?.withRenderingMode(.alwaysTemplate) {
            Image(uiImage: image)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
        }
        Text(title)
    }
}

private extension AppSection {
    var titleKey: String {
        switch self {
        case .home: return "tab.home"
        case .files: return "tab.files"
        case .patches: return "tab.patches"
        case .cleaner: return "tab.cleaner"
        case .wallpapers: return "tab.wallpapers"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .files: return "folder.fill"
        case .patches: return "shippingbox.fill"
        case .cleaner: return "sparkles"
        case .wallpapers: return "photo.on.rectangle.angled"
        }
    }
}

private struct DashboardView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showLogs = false
    @Binding var cleanerEnabled: Bool
    @Binding var wallpapersEnabled: Bool
    let wallpapersSupported: Bool

    var body: some View {
        NavigationStack {
            List {
                deviceSection
                featuresSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.accent)
            .toolbar {
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
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLogs) { LogView() }
        }
    }

    private var featuresSection: some View {
        Section {
            Toggle(isOn: $cleanerEnabled) {
                Label(language.text("tab.cleaner"), systemImage: "sparkles")
            }
            if wallpapersSupported {
                Toggle(isOn: $wallpapersEnabled) {
                    Label(language.text("tab.wallpapers"), systemImage: "photo.on.rectangle.angled")
                }
            }
        } header: {
            Text(language.text("dashboard.features"))
        } footer: {
            Text(language.text("dashboard.features_footer"))
        }
    }

    private var deviceSection: some View {
        Section {
            LabeledContent(language.text("dashboard.hardware_model")) {
                Text(AppInfo.displayMachineName)
                    .font(.body.monospaced())
            }
            LabeledContent(language.text("settings.ios_version")) {
                Text("\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                    .font(.body.monospaced())
            }
            HStack {
                Text(language.text("settings.compatibility"))
                Spacer()
                Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                .foregroundStyle(appState.isSupported ? Color.green : Color.red)
            }

            if appState.kernelExploitApplicable && AppInfo.versionTuple.major < 26 {
                HStack {
                    Text(language.text("dashboard.kernel_status"))
                    Spacer()
                    if appState.kernelExploitRunning {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text(language.text("dashboard.kernel_running"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(language.text(appState.exploitStatus.isSuccess ? "dashboard.kernel_active" : "dashboard.kernel_inactive"))
                        .foregroundStyle(appState.exploitStatus.isSuccess ? Color.green : Color.secondary)
                    }
                }
            }
        } header: {
            Text(language.text("common.device"))
        } footer: {
            Text(language.text("settings.supported_range_summary"))
        }
    }
}
