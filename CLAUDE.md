# CLAUDE.md - TollTrack toll-app

## Project Overview
Norwegian toll calculator iOS app. Shows toll stations on a map, calculates route costs, and tracks search history. Built with SwiftUI + SwiftData (iOS 17+).

## Architecture
**MVVM** with clear separation: Models (SwiftData) / ViewModels (@MainActor ObservableObject) / Views (SwiftUI).

## Key File Paths
- **Entry**: `toll-app/App/toll_appApp.swift`
- **Main Navigation**: `Views/MainTabView.swift` (3 tabs: Travel, History, Settings)
- **Core Flow**: `Views/TravelView.swift` -> `Views/MapView.swift` + `Views/CalculatorView.swift`
- **Services**: `Services/TollService.swift` (NVDB API), `Services/BompengerService.swift` (pricing API)
- **ViewModels**: `ViewModel/MapViewModel.swift` (routes + toll detection), `ViewModel/FeeViewModel.swift` (pricing)
- **Storage**: `ViewModel/TollStorageViewModel.swift`, `ViewModel/FeeStorageViewModel.swift`
 - **Comments**: Never use `// MARK:` comments in code 

## View Hierarchy
```
MainTabView (TabView)
├── Tab 0: TravelView
│   └── MapView (full-screen map + route + toll markers)
│       └── Sheet(CalculatorView) -> From/ToDirectionsView
├── Tab 1: HistoryView
└── Tab 2: SettingsView
```

## External APIs
- **NVDB** (`nvdbapiles.atlas.vegvesen.no`): Toll station data. Returns UTM coordinates (SRID 5973), converted to WGS84 via ArcGIS SDK.
- **Bompenger** (`dibkunnskapapi.azure-api.net`): Real-time toll pricing. API key in `Secrets.xcconfig` -> `Info.plist` (`OCP_APIM_SUBSCRIPTION_KEY`).

## Key Models
- `Vegobjekt` - Toll station (SwiftData). Has `egenskaper: [Egenskap]` and `lokasjon: Lokasjon?`
- `FeeCalculation` - 24h price cache (SwiftData)
- `SearchHistoryItem` - Search history (SwiftData)
- `TollCharge` - Individual toll price (Codable struct)
- Enums: `VehicleType` (car/motorcycle), `FuelType` (electric/diesel/gas), `AppAppearance`

## Coding Conventions
- **Language**: Swift 5.9+, SwiftUI declarative UI
- **Naming**: PascalCase types, camelCase properties/methods
- **State**: `@State private var` for local, `@Published` in ViewModels
- **Concurrency**: async/await everywhere. NO Combine pipelines.
- **ViewModels**: `@MainActor final class`, `ObservableObject`
- **Indentation**: 4 spaces
- **Comments**: Mix of Spanish and English
- **Debug logging**: Wrap in `#if DEBUG`
- **Testing**: Use Swift Testing framework, XCUIAutomation for UI tests

## Key Technical Details
- **Toll detection**: Sample every 10th polyline point, include tolls within 150m of route
- **Price caching**: 24h TTL with expired-cache fallback
- **Toll data refresh**: Monthly via UserDefaults timestamp
- **Rush hours**: 06:30-09:00 and 15:00-17:00 (Norwegian times)
- **Coordinate conversion**: UTM zone 32N (SRID 5973) -> WGS84 using ArcGIS/Esri SDK

## Dependencies
- Apple frameworks: SwiftUI, SwiftData, MapKit, CoreLocation
- Third-party: ArcGIS SDK (coordinate transformation)

## Build
- Min iOS 18.5, Bundle ID: `no.carolina.toll-app`
- API key stored in `Secrets.xcconfig` (gitignored)
