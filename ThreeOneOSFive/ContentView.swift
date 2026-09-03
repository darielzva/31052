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
    @Published var planType: String = "VIP"
    @Published var isAdmin: Bool = false
    @Published var expirationDate: Date = Date().addingTimeInterval(30 * 24 * 3600)
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
                        alertMessage = "Por favor ingresa usuario y key válidos."
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
// 3. VISTA PRINCIPAL (ContentView con tu lógica de parches intacta)
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
                                MainPanelWithUserInfoView(accentColorHex: $accentColorHex, appBackgroundMode: appBackgroundMode)
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
                                    KeysAdminManagementView(accentColorHex: $accentColorHex, appBackgroundMode: appBackgroundMode)
                                        .navigationTitle("Gestión de Keys")
                                        .navigationBarTitleDisplayMode(.inline)
                                        .tint(Color(hexString: accentColorHex))
                                        .toolbar { toolbarContent }
                                }
                            } else {
                                NavigationStack {
                                    PatchProjectsView()
                                        .navigationBarTitleDisplayMode(.inline)
                                        .tint(Color(hexString: accentColorHex))
                                }
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
                .sheet(isPresented: $showSettings) { SettingsView() }
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
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(language.text("accessibility.open_settings"))
        }
    }
}

// ==========================================
// 4. PANEL PRINCIPAL CON TARJETA DE USUARIO
// ==========================================
struct MainPanelWithUserInfoView: View {
    @EnvironmentObject var session: AppSessionManager
    @Binding var accentColorHex: String
    var appBackgroundMode: String
    
    private var iosVersionString: String {
        let version = UIDevice.current.systemVersion
        return "iOS \(version)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
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
                                Text("BIENVENIDO")
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
                            Image(systemName: "power")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                                .padding(8)
                                .background(appBackgroundMode == "black" ? Color(white: 0.15) : Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.2))
                    
                    VStack(spacing: 6) {
                        UserInfoRow(icon: "key.fill", title: "Key:", value: session.currentKey, accent: accentColorHex, appBackgroundMode: appBackgroundMode)
                        UserInfoRow(icon: "clock.fill", title: "Expira en:", value: session.timeRemainingString, accent: accentColorHex, appBackgroundMode: appBackgroundMode)
                        UserInfoRow(icon: "iphone", title: "Dispositivo:", value: iosVersionString, accent: accentColorHex, appBackgroundMode: appBackgroundMode)
                    }
                }
                .padding(12)
                .background(appBackgroundMode == "black" ? Color(white: 0.08) : Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(appBackgroundMode == "black" ? 0 : 0.08), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hexString: accentColorHex).opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 6)
                
                // Aquí se carga tu vista de proyectos y parches original tal cual la tienes
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
// 5. GESTIÓN DE KEYS (Con botones circulares 1d, 7d, 30d y +)
// ==========================================
struct KeysAdminManagementView: View {
    @Binding var accentColorHex: String
    var appBackgroundMode: String
    @State private var customKeyInput: String = ""
    @State private var customDaysInput: String = ""
    @State private var showCustomDaysModal: Bool = false
    @State private var generatedKeysList: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("GENERAR KEYS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        Button(action: { createKeyWithDays(days: 1) }) {
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
                        
                        Button(action: { createKeyWithDays(days: 7) }) {
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
                        
                        Button(action: { createKeyWithDays(days: 30) }) {
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
                        
                        Button(action: { showCustomDaysModal = true }) {
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
                        TextField("Escribe texto personalizado", text: $customKeyInput)
                            .padding()
                            .background(appBackgroundMode == "black" ? Color(white: 0.15) : Color(.systemGray6))
                            .cornerRadius(10)
                            .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
                        
                        Button(action: {
                            createCustomTextKey()
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
                                    .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
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
                            .background(appBackgroundMode == "black" ? Color(white: 0.15) : Color(.systemGray6))
                            .cornerRadius(8)
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
        .alert("Añadir Días Personalizados", isPresented: $showCustomDaysModal) {
            TextField("Número de días (ej. 15)", text: $customDaysInput)
                .keyboardType(.numberPad)
            Button("Generar") {
                if let days = Int(customDaysInput), days > 0 {
                    createKeyWithDays(days: days)
                    customDaysInput = ""
                }
            }
            Button("Cancelar", role: .cancel) {
                customDaysInput = ""
            }
        } message: {
            Text("Ingresa la cantidad de días de vigencia para esta Key.")
        }
    }
    
    private func createKeyWithDays(days: Int) {
        let part1 = randomString(length: 3)
        let part2 = randomString(length: 3)
        let newKey = "DARIEL-\(days)D-\(part1)-\(part2)"
        generatedKeysList.insert(newKey, at: 0)
    }
    
    private func createCustomTextKey() {
        guard !customKeyInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let formatted = customKeyInput.uppercased().replacingOccurrences(of: " ", with: "-")
        let newKey = "DARIEL-\(formatted)"
        generatedKeysList.insert(newKey, at: 0)
        customKeyInput = ""
    }
    
    private func randomString(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

// ==========================================
// 6. COMPONENTES DE NAVEGACIÓN FLOTANTE
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
