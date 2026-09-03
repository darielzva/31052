import SwiftUI
import UIKit
import Combine

// ==========================================
// 1. GESTOR DE SESIÓN Y KEYS (AppSessionManager)
// ==========================================
struct KeyItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    let keyValue: String
    let creationDate: Date
    var expirationDate: Date
    var isRevoked: Bool
}

class AppSessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var username: String = ""
    @Published var currentKey: String = ""
    @Published var planType: String = "VIP"
    @Published var isAdmin: Bool = false
    @Published var expirationDate: Date = Date().addingTimeInterval(30 * 24 * 3600)
    @Published var timeRemainingString: String = "Calculando..."
    
    @Published var savedKeysList: [KeyItem] = []
    
    private var timer: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    func login(user: String, key: String) -> Bool {
        guard !user.isEmpty, !key.isEmpty else { return false }
        
        // Validar si la key está revocada o expirada en la lista generada (si existe)
        if let found = savedKeysList.first(where: { $0.keyValue.lowercased() == key.lowercased() }) {
            if found.isRevoked || found.expirationDate < Date() {
                return false
            }
        }
        
        self.username = user
        self.currentKey = key
        self.isLoggedIn = true
        
        if key == "123" || key.starts(with: "ADMIN") || key.starts(with: "DARIEL") {
            self.isAdmin = true
            self.planType = "ADMIN / VIP"
        } else {
            self.isAdmin = false
            self.planType = key.count > 10 ? "VIP" : "NORMAL"
        }
        
        self.expirationDate = Date().addingTimeInterval(30 * 24 * 3600)
        updateTimeRemaining()
        
        return true
    }
    
    func logout() {
        self.isLoggedIn = false
        self.username = ""
        self.currentKey = ""
        self.isAdmin = false
    }
    
    func createKey(value: String, days: Int) {
        let exp = Date().addingTimeInterval(TimeInterval(days * 24 * 3600))
        let newItem = KeyItem(keyValue: value, creationDate: Date(), expirationDate: exp, isRevoked: false)
        savedKeysList.insert(newItem, at: 0)
    }
    
    func revokeKey(id: String) {
        if let idx = savedKeysList.firstIndex(where: { $0.id == id }) {
            savedKeysList[idx].isRevoked = true
        }
    }
    
    func deleteKey(id: String) {
        savedKeysList.removeAll(with: { $0.id == id })
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimeRemaining()
            }
    }
    
    private func updateTimeRemaining() {
        let remaining = expirationDate.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemainingString = "Expirada"
        } else {
            let days = Int(remaining) / (3600 * 24)
            let hours = (Int(remaining) % (3600 * 24)) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            let seconds = Int(remaining) % 60
            timeRemainingString = "\(days)d \(hours)h \(minutes)m \(seconds)s"
        }
    }
}

extension Array {
    mutating func remove(with condition: (Element) -> Bool) {
        self.removeAll(where: condition)
    }
}

// ==========================================
// 2. VISTA DE INICIO DE SESIÓN (LoginView)
// ==========================================
struct LoginView: View {
    @EnvironmentObject var session: AppSessionManager
    @Binding var accentColorHex: String
    @State private var usernameInput: String = ""
    @State private var keyInput: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hexString: accentColorHex))
                    
                    Text("DARIEL EXTERNAL")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USUARIO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        TextField("Ingresa tu usuario", text: $usernameInput)
                            .padding()
                            .background(Color(white: 0.12))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("KEY (LLAVE DE ACCESO)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        
                        SecureField("Ingresa tu Key", text: $keyInput)
                            .padding()
                            .background(Color(white: 0.12))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    let success = session.login(user: usernameInput, key: keyInput)
                    if !success {
                        alertMessage = "Key inválida, revocada o expirada, o campos vacíos."
                        showAlert = true
                    }
                }) {
                    Text("INGRESAR")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: accentColorHex))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
                
                Text("¿No estás registrado?\nContáctame para obtener acceso.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 30)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Atención"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

// ==========================================
// 3. VISTA PRINCIPAL (ContentView)
// ==========================================
struct ContentView: View {
    @StateObject private var session = AppSessionManager()
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var selectedTab = 0
    @State private var showSettingsSheet = false
    @State private var showLogs = false

    @AppStorage("appBackgroundMode") var appBackgroundMode: String = "black"
    @AppStorage("accentColor") var accentColorHex: String = "FF7F50"

    var body: some View {
        Group {
            if session.isLoggedIn {
                ZStack(alignment: .bottom) {
                    Group {
                        if appBackgroundMode == "black" {
                            Color.black.ignoresSafeArea()
                        } else {
                            Color.white.ignoresSafeArea()
                        }
                    }

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
                                FullSettingsContainerView(accentColorHex: $accentColorHex, appBackgroundMode: appBackgroundMode)
                                    .navigationTitle("Configuración")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .tint(Color(hexString: accentColorHex))
                                    .toolbar {
                                        toolbarContent
                                    }
                            }
                        case 3:
                            if session.isAdmin {
                                NavigationStack {
                                    KeysAdminManagementView(accentColorHex: $accentColorHex, appBackgroundMode: appBackgroundMode)
                                        .navigationTitle("Gestión de Keys")
                                        .navigationBarTitleDisplayMode(.inline)
                                        .tint(Color(hexString: accentColorHex))
                                        .toolbar {
                                            toolbarContent
                                        }
                                }
                            } else {
                                NavigationStack {
                                    PatchProjectsView()
                                        .navigationBarTitleDisplayMode(.inline)
                                        .tint(Color(hexString: accentColorHex))
                                }
                            }
                        default:
                            PatchProjectsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    HStack(spacing: session.isAdmin ? 16 : 28) {
                        FloatingTabButton(icon: "shippingbox.fill", title: "Parches", tag: 0, selectedTab: $selectedTab, accentColorHex: accentColorHex)
                        FloatingTabButton(icon: "arrow.down.circle.fill", title: "Librería", tag: 1, selectedTab: $selectedTab, accentColorHex: accentColorHex)
                        FloatingTabButton(icon: "gearshape.fill", title: "Ajustes", tag: 2, selectedTab: $selectedTab, accentColorHex: accentColorHex)
                        
                        if session.isAdmin {
                            FloatingTabButton(icon: "key.fill", title: "Keys", tag: 3, selectedTab: $selectedTab, accentColorHex: accentColorHex)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(38)
                    .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
                    .padding(.horizontal, 15)
                    .padding(.bottom, 20)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .tint(Color(hexString: accentColorHex))
                .imageScale(.medium)
                .preferredColorScheme(appBackgroundMode == "black" ? .dark : .light)
                .sheet(isPresented: $showSettingsSheet) {
                    NavigationStack {
                        FullSettingsContainerView(accentColorHex: $accentColorHex, appBackgroundMode: appBackgroundMode)
                            .navigationTitle("Configuración")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") { showSettingsSheet = false }
                                }
                            }
                    }
                }
                .sheet(isPresented: $showLogs) { LogView() }
                .environmentObject(session)
            } else {
                LoginView(accentColorHex: $accentColorHex)
                    .environmentObject(session)
            }
        }
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
            Button { showSettingsSheet = true } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(language.text("accessibility.open_settings"))
        }
    }
}

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

// ==========================================
// 4. LIBRERÍA ANTIGUA (100% Intacta)
// ==========================================
struct LibraryDownloadView: View {
    @State private var selectedLibraryTab: LibraryTabType = .aim
    @State private var alertMessage = ""
    @State private var showAlert = false
    @Binding var accentColorHex: String

    var body: some View {
        VStack(spacing: 0) {
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

// ==========================================
// 5. CONFIGURACIÓN COMPLETA (Sesión + Tus Ajustes Originales)
// ==========================================
struct FullSettingsContainerView: View {
    @EnvironmentObject var session: AppSessionManager
    @Binding var accentColorHex: String
    var appBackgroundMode: String
    
    private var iosVersionString: String {
        let version = UIDevice.current.systemVersion
        return "iOS \(version)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tarjeta de sesión actual
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(appBackgroundMode == "black" ? Color(white: 0.15) : Color(.systemGray5))
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(hexString: accentColorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("SESIÓN ACTUAL")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text("• \(session.planType)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(hexString: accentColorHex))
                            }
                            Text(session.username)
                                .font(.subheadline.bold())
                                .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            session.logout()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "power")
                                Text("Salir")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.2))
                    
                    VStack(spacing: 6) {
                        UserInfoRow(icon: "key.fill", title: "Key:", value: session.currentKey, accent: accentColorHex, appBackgroundMode: appBackgroundMode)
                        UserInfoRow(icon: "clock.fill", title: "Expira en:", value: session.timeRemainingString, accent: accentColorHex, appBackgroundMode: appBackgroundMode)
                        UserInfoRow(icon: "iphone", title: "Dispositivo:", value: iosVersionString, accent: accentColorHex, appBackgroundMode: appBackgroundMode)
                    }
                }
                .padding(14)
                .background(appBackgroundMode == "black" ? Color(white: 0.08) : Color(.systemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hexString: accentColorHex).opacity(0.3), lineWidth: 1)
                )
                
                // Tus ajustes originales completos (incluyendo selectores de color, tema, etc.)
                SettingsView()
            }
            .padding()
        }
    }
}

private struct UserInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let accent: String
    var appBackgroundMode: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hexString: accent))
                .font(.system(size: 13))
                .frame(width: 18)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// ==========================================
// 6. GESTIÓN DE KEYS (Control avanzado: Revocar, Vencer, Eliminar y Custom Text + Días)
// ==========================================
struct KeysAdminManagementView: View {
    @EnvironmentObject var session: AppSessionManager
    @Binding var accentColorHex: String
    var appBackgroundMode: String
    
    @State private var customTextPrefix: String = ""
    @State private var customDaysInput: String = ""
    @State private var showCustomModal: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Sección de generación con botones circulares 1, 7, 30 y +
                VStack(alignment: .leading, spacing: 12) {
                    Text("GENERAR KEYS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Button(action: { createKeyStandard(days: 1) }) {
                            VStack(spacing: 2) {
                                Text("1")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Día")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(Color(hexString: accentColorHex))
                            .clipShape(Circle())
                        }
                        
                        Button(action: { createKeyStandard(days: 7) }) {
                            VStack(spacing: 2) {
                                Text("7")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Días")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(Color(hexString: accentColorHex))
                            .clipShape(Circle())
                        }
                        
                        Button(action: { createKeyStandard(days: 30) }) {
                            VStack(spacing: 2) {
                                Text("30")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Días")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(Color(hexString: accentColorHex))
                            .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: { showCustomModal = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 52, height: 52)
                                .background(Color(hexString: accentColorHex))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 8) {
                        TextField("Texto personalizado (ej. 123)", text: $customTextPrefix)
                            .padding()
                            .background(appBackgroundMode == "black" ? Color(white: 0.15) : Color(.systemGray6))
                            .cornerRadius(10)
                            .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
                        
                        Button(action: {
                            createCustomKeyWithDefaultDays()
                        }) {
                            Text("Crear")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(hexString: accentColorHex))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(16)
                .background(appBackgroundMode == "black" ? Color(white: 0.08) : Color(.systemBackground))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hexString: accentColorHex).opacity(0.3), lineWidth: 1))
                
                // Listado de Keys con opciones de control total
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("KEYS ACTIVAS Y REGISTRO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(session.savedKeysList.count) Totales")
                            .font(.caption)
                            .foregroundColor(Color(hexString: accentColorHex))
                    }
                    
                    if session.savedKeysList.isEmpty {
                        Text("No hay keys generadas aún.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(session.savedKeysList) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.keyValue)
                                        .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
                                        .font(.system(size: 13, design: .monospaced).bold())
                                    
                                    Spacer()
                                    
                                    if item.isRevoked {
                                        Text("REVOCADA")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.2))
                                            .cornerRadius(4)
                                    } else if item.expirationDate < Date() {
                                        Text("EXPIRADA")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .cornerRadius(4)
                                    } else {
                                        Text("ACTIVA")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        UIPasteboard.general.string = item.keyValue
                                    }) {
                                        Label("Copiar", systemImage: "doc.on.doc")
                                            .font(.system(size: 11))
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    if !item.isRevoked {
                                        Button(action: {
                                            session.revokeKey(id: item.id)
                                        }) {
                                            Label("Revocar", systemImage: "xmark.shield")
                                                .font(.system(size: 11))
                                                .foregroundColor(.orange)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        session.deleteKey(id: item.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.system(size: 13))
                                    }
                                }
                            }
                            .padding()
                            .background(appBackgroundMode == "black" ? Color(white: 0.15) : Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(16)
                .background(appBackgroundMode == "black" ? Color(white: 0.08) : Color(.systemBackground))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hexString: accentColorHex).opacity(0.3), lineWidth: 1))
            }
            .padding()
        }
        .alert("Key Personalizada con Días", isPresented: $showCustomModal) {
            TextField("Texto de Key (ej. 123)", text: $customTextPrefix)
            TextField("Cantidad de días (ej. 7)", text: $customDaysInput)
                .keyboardType(.numberPad)
            Button("Crear Key") {
                if let days = Int(customDaysInput), days > 0, !customTextPrefix.trimmingCharacters(in: .whitespaces).isEmpty {
                    let formatted = customTextPrefix.uppercased().replacingOccurrences(of: " ", with: "-")
                    session.createKey(value: formatted, days: days)
                    customTextPrefix = ""
                    customDaysInput = ""
                }
            }
            Button("Cancelar", role: .cancel) {
                customTextPrefix = ""
                customDaysInput = ""
            }
        } message: {
            Text("Ingresa el texto personalizado (por ejemplo '123') y los días de vigencia exactos.")
        }
    }
    
    private func createKeyStandard(days: Int) {
        let p1 = randomString(length: 3)
        let p2 = randomString(length: 3)
        let newKey = "DARIEL-\(days)D-\(p1)-\(p2)"
        session.createKey(value: newKey, days: days)
    }
    
    private func createCustomKeyWithDefaultDays() {
        guard !customTextPrefix.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let formatted = customTextPrefix.uppercased().replacingOccurrences(of: " ", with: "-")
        // Si ingresó texto personalizado como "123", por defecto lo creamos a 7 días (o puedes cambiarlo)
        session.createKey(value: formatted, days: 7)
        customTextPrefix = ""
    }
    
    private func randomString(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
