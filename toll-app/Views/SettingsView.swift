import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var icon: String {
        switch self {
        case .automatic: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct SettingsView: View {
    @AppStorage("appAppearance") private var appearance: String = AppAppearance.automatic.rawValue
    @AppStorage("defaultVehicle") private var defaultVehicle: String = VehicleType.car.rawValue
    @AppStorage("defaultFuel") private var defaultFuel: String = FuelType.gas.rawValue
    @AppStorage("defaultAutopass") private var defaultAutopass: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .automatic
    }
    
    var body: some View {
        NavigationView {
            List {
                appearanceSection
                defaultsSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Appearance
    private var appearanceSection: some View {
        Section {
            ForEach(AppAppearance.allCases) { option in
                Button {
                    appearance = option.rawValue
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: option.icon)
                            .foregroundStyle(option == selectedAppearance ? .blue : .secondary)
                            .frame(width: 24)
                        
                        Text(option.rawValue)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if option == selectedAppearance {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            Text("APPEARANCE")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    // MARK: - Defaults
    private var defaultsSection: some View {
        Section {
            // Vehicle
            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                Text("Vehicle")
                
                Spacer()
                
                Picker("", selection: $defaultVehicle) {
                    ForEach(VehicleType.allCases) { type in
                        Text(type.rawValue.capitalized).tag(type.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Fuel
            HStack(spacing: 12) {
                let fuel = FuelType(rawValue: defaultFuel) ?? .gas
                Image(systemName: fuel == .electric ? "bolt.fill" : "fuelpump.fill")
                    .foregroundStyle(fuel == .electric ? .green : fuel == .diesel ? .gray : .orange)
                    .frame(width: 24)
                
                Text("Fuel")
                
                Spacer()
                
                Picker("", selection: $defaultFuel) {
                    ForEach(FuelType.allCases) { type in
                        Text(type.rawValue.capitalized).tag(type.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // AutoPass
            HStack(spacing: 12) {
                Image(systemName: defaultAutopass ? "checkmark.shield.fill" : "shield.slash.fill")
                    .foregroundStyle(defaultAutopass ? .blue : .secondary)
                    .frame(width: 24)
                
                Toggle("AutoPass", isOn: $defaultAutopass)
            }
        } header: {
            Text("DEFAULTS")
                .font(.caption)
                .fontWeight(.semibold)
        } footer: {
            Text("These will be pre-selected when you open the calculator.")
                .font(.caption2)
        }
    }
    
    // MARK: - About
    private var aboutSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                
                Text("Version")
                
                Spacer()
                
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("ABOUT")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    SettingsView()
}
