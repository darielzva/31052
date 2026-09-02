import SwiftUI
import UIKit
import Combine

// ==========================================
// 1. GESTOR DE SESIÓN Y KEYS (AppSessionManager)
// ==========================================
class AppSessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var username: String = ""
    @Published var currentKey: String = ""
    @Published var planType: String = "VIP" // VIP o NORMAL
    @Published var isAdmin: Bool = false
    @Published var expirationDate: Date = Date().addingTimeInterval(30 * 24 * 3600) // 30 días de prueba inicial
    @Published var timeRemainingString: String = "Calculando..."
    
    private var timer: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    func login(user: String, key: String) -> Bool {
        guard !user.isEmpty, !key.isEmpty else { return false }
        
        self.username = user
        self.currentKey = key
        self.isLoggedIn = true
        
        if key == "123" || key.starts(with: "ADMIN") {
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

// ==========================================
// 2. VISTA DE INICIO DE SESIÓN (LoginView)
// ==========================================
struct LoginView: View {
    @EnvironmentObject var session: AppSessionManager
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
                        .foregroundColor(Color(hexString: "FFD700"))
                    
                    Text("INICIAR SESIÓN")
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
                        alertMessage = "Por favor ingresa usuario y key válidos."
                        showAlert = true
                    }
                }) {
                    Text("INGRESAR")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hexString: "FFD700"))
                        .cornerRadius(14)
                        .shadow(color: Color(hexString: "FFD700").opacity(0.4), radius: 8, x: 0, y: 0)
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
// 3. VISTA PRINCIPAL (ContentView Modificado)
// ==========================================
struct ContentView: View {
    @StateObject private var session = AppSessionManager()
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @State private var selectedTab = 0
    @State private var showSettings = false
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
                                MainPanelWithUserInfoView(accentColorHex: $accentColorHex)
                                    .navigationBarTitleDisplayMode(.inline)
                                    .tint(Color(hexString: accentColorHex))
                                    .toolbar { toolbarContent }
                            }
                        case 1:
                            NavigationStack {
                                LibraryDownloadView(accentColorHex: $accentColorHex)
                                    .navigationTitle("Librería")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .tint(Color(hexString: accentColorHex))
                                    .toolbar { toolbarContent }
                            }
                        case 2:
                            NavigationStack {
                                SettingsView()
                                    .navigationTitle("Configuración")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .tint(Color(hexString: accentColorHex))
                            }
                        case 3:
                            if session.isAdmin {
                                NavigationStack {
                                    KeysAdminManagementView(accentColorHex: $accentColorHex)
                                        .navigationTitle("Gestión de Keys")
                                        .navigationBarTitleDisplayMode(.inline)
                                        .tint(Color(hexString: accentColorHex))
                                        .toolbar { toolbarContent }
                                }
                            } else {
                                PatchProjectsView()
                            }
                        default:
                            PatchProjectsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    HStack(spacing: session.isAdmin ? 16 : 24) {
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
                .sheet(isPresented: $showSettings) { SettingsView() }
                .sheet(isPresented: $showLogs) { LogView() }
                .environmentObject(session)
            } else {
                LoginView()
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
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(language.text("accessibility.open_settings"))
        }
    }
}

// ==========================================
// 4. PANEL PRINCIPAL CON TARJETA DE USUARIO E IOS
// ==========================================
struct MainPanelWithUserInfoView: View {
    @EnvironmentObject var session: AppSessionManager
    @Binding var accentColorHex: String
    
    private var iosVersionString: String {
        let version = UIDevice.current.systemVersion
        return "iOS \(version)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hexString: accentColorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("BIENVENIDO")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                Text("• \(session.planType)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hexString: accentColorHex))
                            }
                            Text(session.username)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            session.logout()
                        }) {
                            Image(systemName: "power")
                                .foregroundColor(.red)
                                .padding(10)
                                .background(Color(white: 0.12))
                                .clipShape(Circle())
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    VStack(spacing: 8) {
                        UserInfoRow(icon: "key.fill", title: "Key:", value: session.currentKey, accent: accentColorHex)
                        UserInfoRow(icon: "clock.fill", title: "Expira en:", value: session.timeRemainingString, accent: accentColorHex)
                        UserInfoRow(icon: "iphone", title: "Dispositivo:", value: iosVersionString, accent: accentColorHex)
                    }
                }
                .padding(16)
                .background(Color(white: 0.08))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hexString: accentColorHex).opacity(0.4), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 10)
                
                PatchProjectsView()
            }
        }
    }
}

private struct UserInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let accent: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Color(hexString: accent))
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 4)
    }
}

// ==========================================
// 5. VISTA DE GESTIÓN DE KEYS PARA ADMIN
// ==========================================
struct KeysAdminManagementView: View {
    @Binding var accentColorHex: String
    @State private var customDays: String = ""
    @State private var generatedKeysList: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("GENERAR NUEVA KEY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Button(action: { createKey(days: 1) }) { Text("1D").adminKeyBtnStyle(accent: accentColorHex) }
                        Button(action: { createKey(days: 5) }) { Text("5D").adminKeyBtnStyle(accent: accentColorHex) }
                        Button(action: { createKey(days: 7) }) { Text("7D").adminKeyBtnStyle(accent: accentColorHex) }
                        Button(action: { createKey(days: 30) }) { Text("30D").adminKeyBtnStyle(accent: accentColorHex) }
                    }
                    
                    TextField("Días personalizados", text: $customDays)
                        .padding()
                        .background(Color(white: 0.15))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                    
                    Button(action: {
                        if let days = Int(customDays), days > 0 {
                            createKey(days: days)
                            customDays = ""
                        }
                    }) {
                        Text("GENERAR PERSONALIZADA")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hexString: accentColorHex))
                            .cornerRadius(10)
                    }
                }
                .padding(16)
                .background(Color(white: 0.1))
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("KEYS ACTIVAS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(generatedKeysList.count) Totales")
                            .font(.caption)
                            .foregroundColor(Color(hexString: accentColorHex))
                    }
                    
                    if generatedKeysList.isEmpty {
                        Text("No hay keys generadas aún.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(generatedKeysList, id: \.self) { key in
                            HStack {
                                Text(key)
                                    .foregroundColor(.white)
                                    .font(.system(size: 13, design: .monospaced))
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = key
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(Color(hexString: accentColorHex))
                                }
                            }
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
                .background(Color(white: 0.1))
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    private func createKey(days: Int) {
        let randomCode = String(Int.random(in: 100000..<999999))
        let newKey = "LEAL-\(days)D-\(randomCode)"
        generatedKeysList.insert(newKey, at: 0)
    }
}

private extension View {
    func adminKeyBtnStyle(accent: String) -> some View {
        self.font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(white: 0.15))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hexString: accent).opacity(0.5), lineWidth: 1))
    }
}

// ==========================================
// 6. COMPONENTES DE NAVEGACIÓN Y LIBRERÍA
// ==========================================
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
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                
                if selectedTab == tag {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, selectedTab == tag ? 14 : 10)
            .foregroundColor(selectedTab == tag ? .white : .gray)
            .background(selectedTab == tag ? Color(hexString: accentColorHex) : Color.clear)
            .cornerRadius(20)
        }
    }
}

private enum LibraryTabType {
    case aim, visual
}

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
            alertMessage = "Archivo \(displayName) descargado con éxito."
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
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundStyle(.secondary)
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
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundStyle(.secondary)
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
