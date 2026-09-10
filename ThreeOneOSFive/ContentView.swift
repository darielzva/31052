import SwiftUI
import UIKit
import Combine

// ==========================================
// 1. VISTA PRINCIPAL (ContentView)
// ==========================================
struct ContentView: View {
    @Environment(\.appLanguage) private var language
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

            // Contenedor principal de pestañas (Únicamente Parches y Ajustes)
            Group {
                switch selectedTab {
                case 0:
                    NavigationStack {
                        PatchProjectsView(accentColorHex: $accentColorHex, appBackgroundMode: $appBackgroundMode)
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(Color(hexString: accentColorHex))
                            .toolbar {
                                toolbarContent
                            }
                    }
                case 1:
                    NavigationStack {
                        SettingsContainerView(accentColorHex: $accentColorHex, appBackgroundMode: appBackgroundMode)
                            .navigationTitle("Configuración")
                            .navigationBarTitleDisplayMode(.inline)
                            .tint(Color(hexString: accentColorHex))
                    }
                default:
                    PatchProjectsView(accentColorHex: $accentColorHex, appBackgroundMode: $appBackgroundMode)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Barra de navegación flotante estilo pastilla personalizada (2 opciones)
            HStack(spacing: 32) {
                FloatingTabButton(icon: "shippingbox.fill", title: "Parches", tag: 0, selectedTab: $selectedTab, accentColorHex: accentColorHex)
                FloatingTabButton(icon: "gearshape.fill", title: "Ajustes", tag: 1, selectedTab: $selectedTab, accentColorHex: accentColorHex)
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
        .sheet(isPresented: $showSettings) { SettingsView(accentColorHex: $accentColorHex, appBackgroundMode: $appBackgroundMode) }
        .sheet(isPresented: $showLogs) { LogView(appBackgroundMode: $appBackgroundMode) }
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
// 2. BOTÓN DE PESTAÑA FLOTANTE
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

// ==========================================
// 3. CONTENEDOR DE AJUSTES
// ==========================================
struct SettingsContainerView: View {
    @Binding var accentColorHex: String
    var appBackgroundMode: String
    
    private var iosVersionString: String {
        let version = UIDevice.current.systemVersion
        return "iOS \(version)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tarjeta de información general del sistema
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(appBackgroundMode == "black" ? Color(white: 0.15) : Color(.systemGray5))
                                .frame(width: 40, height: 40)
                            Image(systemName: "iphone")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hexString: accentColorHex))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SISTEMA")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(iosVersionString)
                                .font(.subheadline.bold())
                                .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(14)
                .background(appBackgroundMode == "black" ? Color(white: 0.08) : Color(.systemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hexString: accentColorHex).opacity(0.3), lineWidth: 1)
                )
                
                // Vista completa de ajustes de la aplicación
                SettingsView(accentColorHex: $accentColorHex, appBackgroundMode: .constant(appBackgroundMode))
            }
            .padding()
        }
    }
}

// ==========================================
// 4. VISTA DE PARCHES (PatchProjectsView Completa)
// ==========================================
struct PatchProjectsView: View {
    @Binding var accentColorHex: String
    @Binding var appBackgroundMode: String
    
    @State private var patchesList: [PatchItem] = []
    @State private var showAddPatchSheet = false
    @State private var newPatchName = ""
    @State private var newPatchDescription = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Group {
                if appBackgroundMode == "black" {
                    Color.black.ignoresSafeArea()
                } else {
                    Color.white.ignoresSafeArea()
                }
            }

            VStack(spacing: 0) {
                if patchesList.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No hay parches agregados")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Importa o crea nuevos parches para comenzar.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(patchesList) { patch in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hexString: accentColorHex).opacity(0.2))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: patch.isActive ? "checkmark.shield.fill" : "shield.slash.fill")
                                        .foregroundColor(patch.isActive ? Color(hexString: accentColorHex) : .gray)
                                        .font(.system(size: 20))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(patch.name)
                                        .font(.headline)
                                        .foregroundColor(appBackgroundMode == "black" ? .white : .primary)
                                    Text(patch.descriptionText)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { patch.isActive },
                                    set: { newValue in
                                        togglePatchStatus(patch: patch, status: newValue)
                                    }
                                ))
                                .labelsHidden()
                                .tint(Color(hexString: accentColorHex))
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(appBackgroundMode == "black" ? Color(white: 0.08) : Color(.systemBackground))
                        }
                        .onDelete(perform: deletePatch)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Parches")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddPatchSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .sheet(isPresented: $showAddPatchSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Detalles del Parche")) {
                        TextField("Nombre del Parche", text: $newPatchName)
                        TextField("Descripción", text: $newPatchDescription)
                    }
                }
                .navigationTitle("Nuevo Parche")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { showAddPatchSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            addNewPatch()
                        }
                        .disabled(newPatchName.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            loadPatches()
        }
    }

    private func addNewPatch() {
        let newPatch = PatchItem(name: newPatchName, descriptionText: newPatchDescription, isActive: false)
        patchesList.append(newPatch)
        savePatches()
        newPatchName = ""
        newPatchDescription = ""
        showAddPatchSheet = false
    }

    private func togglePatchStatus(patch: PatchItem, status: Bool) {
        if let index = patchesList.firstIndex(where: { $0.id == patch.id }) {
            patchesList[index].isActive = status
            savePatches()
        }
    }

    private func deletePatch(at offsets: IndexSet) {
        patchesList.remove(atOffsets: offsets)
        savePatches()
    }

    private func savePatches() {
        if let encoded = try? JSONEncoder().encode(patchesList) {
            UserDefaults.standard.set(encoded, forKey: "saved_patches_list")
        }
    }

    private func loadPatches() {
        if let data = UserDefaults.standard.data(forKey: "saved_patches_list"),
           let decoded = try? JSONDecoder().decode([PatchItem].self, from: data) {
            patchesList = decoded
        }
    }
}

struct PatchItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var descriptionText: String
    var isActive: Bool
}

// ==========================================
// 5. VISTA DE AJUSTES (SettingsView Completa)
// ==========================================
struct SettingsView: View {
    @Binding var accentColorHex: String
    @Binding var appBackgroundMode: String
    
    let availableColors = [
        ("Coral", "FF7F50"),
        ("Azul", "007AFF"),
        ("Verde", "34C759"),
        ("Morado", "AF52DE"),
        ("Naranja", "FF9500"),
        ("Rosa", "FF2D55")
    ]

    var body: some View {
        Form {
            Section(header: Text("Apariencia y Tema")) {
                Picker("Modo de Fondo", selection: $appBackgroundMode) {
                    Text("Negro Puro").tag("black")
                    Text("Blanco / Sistema").tag("white")
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Color de Acentuación")) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                    ForEach(availableColors, id: \.1) { name, hex in
                        ZStack {
                            Circle()
                                .fill(Color(hexString: hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: accentColorHex == hex ? 3 : 0)
                                )
                                .shadow(radius: accentColorHex == hex ? 4 : 0)
                                .onTapGesture {
                                    accentColorHex = hex
                                }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section(header: Text("Acerca de la Aplicación")) {
                HStack {
                    Text("Versión")
                    Spacer()
                    Text("1.0.0 (Clean Build)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Desarrollador")
                    Spacer()
                    Text("Dariel")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// ==========================================
// 6. VISTA DE LOGS (LogView Completa)
// ==========================================
struct LogView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var appBackgroundMode: String
    @State private var logEntries: [String] = [
        "[INFO] Aplicación inicializada correctamente.",
        "[DEBUG] Cargando entorno gráfico de parches...",
        "[SUCCESS] Conexión local establecida sin errores.",
        "[INFO] Sistema de sesiones y llaves removido por completo."
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    if appBackgroundMode == "black" {
                        Color.black.ignoresSafeArea()
                    } else {
                        Color(.systemGroupedBackground).ignoresSafeArea()
                    }
                }

                List {
                    ForEach(logEntries, id: \.self) { log in
                        Text(log)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(appBackgroundMode == "black" ? Color.green : Color.primary)
                            .listRowBackground(appBackgroundMode == "black" ? Color(white: 0.08) : Color(.systemBackground))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Consola de Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpiar") {
                        logEntries.removeAll()
                    }
                }
            }
        }
    }
}

// ==========================================
// 7. EXTENSIÓN DE COLOR (Para códigos Hex)
// ==========================================
extension Color {
    init(hexString: String) {
        let scanner = Scanner(string: hexString)
        _ = scanner.scanString("#")
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
