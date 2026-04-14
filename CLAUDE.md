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
- **TollPassedListView sheet**: Uses `ScrollView` with `.scrollDisabled(true)` + `.presentationContentInteraction(.resizes)` — scroll is disabled so the sheet itself handles swipe up/down. Do NOT remove ScrollView (needed for NavigationBar inset spacing) and do NOT use plain VStack (causes title overlap).
- **Toll detection**: Sample every 10th polyline point, include tolls within 150m of route
- **Price caching**: 24h TTL with expired-cache fallback. Cache key version: v6
- **Toll data refresh**: `mapVM.fetchTolls()` calls NVDB fresh on every MapView appear. `TollStorageViewModel` caches for pricing but `updateTollsIfNeeded()` is currently never called — data loaded once at first launch.
- **Rush hours**: Per-station from NVDB egenskaper (`Rushtid morgen fra/til`, `Rushtid ettermiddag fra/til`). Falls back to 06:30-09:00 and 15:00-17:00 if not set.
- **Coordinate conversion**: UTM zone 32N (SRID 5973) -> WGS84 using ArcGIS/Esri SDK
- **NVDB prices**: Already are AutoPASS rates — do NOT apply extra AutoPASS discount
- **EV discount**: 50% of the NVDB AutoPASS base price (Norwegian law minimum)
- **Trondheim price correction (×1.12)**: Applied via `isOutdatedNVDBStation` using `Operatør_Id`: 100120 = Vegamot AS (all snitt stations), 100149 = Ranheim standalone (operator changed 2023-11-01). Both have NVDB prices not updated after Feb 2024. Remove multiplier when NVDB is updated. Do NOT use name-based "snitt" detection — it incorrectly includes 3 Stavanger stations (Ferde AS, operator 100014) that have correct NVDB prices.
- **Timesregel**: Handled in FeeViewModel. Stations sharing `passeringsgruppe`: "Første passering gjelder" → only charge first; "Dyreste passering gjelder" → only charge most expensive in group.
- **AutoPASS toggle in Settings**: Does not affect pricing (NVDB prices are already AutoPASS rates). Toggle is kept in UI for future use.

## NVDB Data Notes
- Vegobjekttype 45 (Bomstasjon) is the only free source for Norwegian toll prices — no better endpoint exists
- Prices flow automatically from AutoPASS IP system into NVDB, but some operators (e.g. Vegamot) lag behind
- All other major cities (Bergen, Oslo, Stavanger, Tromsø, etc.) have current prices in NVDB
- NVDB does not have EV-specific price fields — 50% discount is applied in code

## Dependencies
- Apple frameworks: SwiftUI, SwiftData, MapKit, CoreLocation
- Third-party: ArcGIS SDK (coordinate transformation)

## Build
- Min iOS 18.5, Bundle ID: `no.carolina.toll-app`
- API key stored in `Secrets.xcconfig` (gitignored)
