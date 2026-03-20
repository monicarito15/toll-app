# Toll App - Norwegian Toll Calculator

A SwiftUI-based iOS application that calculates toll costs for routes in Norway using real-time data from the NVDB (Norwegian Road Database) API.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Installation](#installation)
- [Usage](#usage)
- [Technical Details](#technical-details)
- [API Integration](#api-integration)

---

## Overview

This app helps drivers in Norway calculate toll costs for their routes. It fetches toll station data from the NVDB API, stores it locally using SwiftData for offline access, and calculates routes using MapKit to identify which toll stations are along the way.

**Current Status**: The app successfully identifies toll stations on a route but price calculation is not yet implemented (returns $0).

---

## Features

### Implemented

- **Route Calculation**: Calculate routes between two addresses using MapKit
- **Current Location Integration**: Automatically detect and use your current location as starting point
- **Toll Station Detection**: Identifies toll stations within 350 meters of your calculated route
- **Offline Support**: Toll data cached locally using SwiftData
- **Search History**: Saves recent searches for quick access
- **Nearby Tolls**: Shows toll stations near your current location
- **Vehicle & Fuel Type Selection**: Choose between car/motorcycle and gas/electric
- **Date & Time Selection**: Select when you'll be traveling
- **Autopass Toggle**: Indicate if you have an Autopass account

### In Development

- **Price Calculation**: Calculate actual toll costs based on vehicle type, fuel type, time, and Autopass status
- **Route Alternatives**: Show multiple route options with different toll costs

---

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern with SwiftUI and Swift Concurrency (async/await).

```
┌─────────────────────────────────────────────────────────────┐
│                          Views                               │
│  (CalculatorView, NearbyTolls, TollMapView, etc.)          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                       ViewModels                             │
│  • MapViewModel (route calculation, toll detection)         │
│  • TollStorageViewModel (local data management)             │
│  • LocationManager (location services)                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Services & Data                            │
│  • TollService (API calls)                                  │
│  • SwiftData (local persistence)                            │
│  • MapKit (routing)                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### Views

#### `CalculatorView`
The main interface for route calculation.

**Features:**
- From/To address input fields
- Current location button with geocoding
- Date/time picker for travel planning
- Vehicle and fuel type selectors
- Autopass toggle
- Nearby tolls list with tap-to-select functionality

**Key Code Highlights:**
```swift
// Simplified body structure (refactored to avoid compiler timeout)
var body: some View {
    NavigationView {
        ScrollView {
            VStack(spacing: 20) {
                routeAndTimeSection      // From/To/Date inputs
                vehicleDetailsSection    // Vehicle/Fuel/Autopass
                calculateButton          // Calculate route action
                nearbyTollsSection       // Nearby toll stations
            }
        }
    }
}
```

#### `NearbyTolls`
Displays a list of toll stations near the user's current location.

**Features:**
- Distance calculation from user to toll
- Sorting by nearest first
- Tap to auto-fill destination in CalculatorView

#### `TollMapView`
Displays the map with route, toll markers, and user location.

**Features:**
- Interactive map with route overlay
- Toll station annotations
- Auto-zoom to fit route bounds
- Camera position management

---

### ViewModels

#### `MapViewModel`
The brain of the app - handles routing, toll detection, and location management.

**Key Responsibilities:**
- Route calculation using MapKit
- Toll station data management
- User location tracking
- Toll detection along routes

**Important Methods:**
```swift
// Calculate route between two coordinates
func getDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async

// Geocode addresses to coordinates, then calculate route
func getDirectionsFromAddresses(fromAddress: String, toAddress: String) async

// Identify tolls within 350m of route
func buildResultIfPossible(vehicle: VehicleType, fuel: FuelType, date: Date)

// Filter tolls near the route polyline
private func tollsNearRoute(route: MKRoute, tolls: [Vegobjekt], maxDistanceMeters: Double) -> [Vegobjekt]
```

**Published Properties:**
```swift
@Published var route: MKRoute?                        // Calculated route
@Published var toll: [Vegobjekt] = []                 // All toll stations
@Published var userLocation: CLLocationCoordinate2D?  // User's location
@Published var hasResult: Bool = false                // Show result bar
@Published var tollsOnRoute: [Vegobjekt] = []         // Tolls on current route
@Published var totalPrice: Double = 0                 // Total cost (currently 0)
```

#### `TollStorageViewModel`
Manages local toll data persistence using SwiftData.

**Key Responsibilities:**
- Load tolls from local database
- Fetch from API if local data is empty
- Automatic monthly updates (checks if data is older than 1 month)
- Data synchronization

**Important Methods:**
```swift
// Load tolls from SwiftData, fetch from API if empty
func loadTolls(using modelContext: ModelContext) async

// Fetch from API and save to SwiftData
private func fetchAndSaveFromApi(using modelContext: ModelContext) async throws

// Check if we should update from API (> 1 month old)
func shouldUpdateFromAPI() -> Bool

// Update tolls if needed and save update date
func updateTollsIfNeeded(using modelContext: ModelContext) async
```

#### `LocationManager`
Handles all Core Location functionality.

**Features:**
- Real-time location updates
- Authorization status management
- Reverse geocoding (coordinates → address)
- One-time location requests

**Published Properties:**
```swift
@Published var userLocation: CLLocationCoordinate2D?
@Published var authorizationStatus: CLAuthorizationStatus?
@Published var currentAddress: String?
```

---

### Services

#### `TollService`
API client for the NVDB (Norwegian Road Database).

**API Endpoint:**
```
https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45
```

**Parameters:**
- `inkluder=lokasjon` - Include location data
- `inkluder=egenskaper` - Include properties (name, etc.)

**Headers:**
```swift
Accept: application/json
X-Client: toll-app (carolina.m@gmail.com)
```

**Key Method:**
```swift
func getTolls() async throws -> [Vegobjekt]
```

**Error Handling:**
```swift
enum GHError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
```

---

### Models

#### `Vegobjekt` (Toll Station)
Main toll station model stored in SwiftData.

**Properties:**
- `id: Int` - Unique identifier
- `href: String` - API reference URL
- `egenskaper: [Egenskap]` - Properties (name, etc.)
- `lokasjon: Lokasjon?` - Geographic location

#### `Egenskap` (Property)
Key-value properties of a toll station.

**Properties:**
- `id: Int`
- `navn: String` - Property name (e.g., "Navn bomstasjon")
- `verdi: String?` - Property value (e.g., "Oslo Toll Station")

#### `Lokasjon` (Location)
Geographic location data.

**Properties:**
- `geometri: Geometri` - Geometry data

**Computed Property:**
```swift
var coordinates: CLLocationCoordinate2D? {
    // Parses WKT format: "POINT (10.7522 59.9139)"
    // Returns CLLocationCoordinate2D
}
```

#### `Geometri` (Geometry)
Raw geographic data from NVDB.

**Properties:**
- `wkt: String` - Well-Known Text format (e.g., "POINT (10.7522 59.9139)")
- `srid: Int` - Spatial Reference System ID

#### `RecentSearch`
User's search history stored in SwiftData.

**Properties:**
- `name: String` - Search name
- `address: String` - Full address
- `createdAt: Date` - When saved
- `vehicleType: VehicleType?`
- `fuelType: FuelType?`

#### Enums

```swift
enum VehicleType: String, Codable, CaseIterable, Identifiable {
    case car
    case motorcycle
}

enum FuelType: String, Codable, CaseIterable, Identifiable {
    case electric
    case gas
}
```

---

## Data Flow

### 1. App Launch

```
toll_appApp.swift
    ↓
Creates ModelContainer with SwiftData models
    ↓
Loads MainTabView with injected modelContainer
    ↓
TollStorageViewModel checks local data
    ↓
If empty: Fetch from NVDB API
    ↓
Save to SwiftData for offline access
```

### 2. Route Calculation

```
User enters addresses in CalculatorView
    ↓
Taps "Calculate Route"
    ↓
MapViewModel.getDirectionsFromAddresses()
    ↓
Geocode addresses to coordinates
    ↓
MapViewModel.getDirections()
    ↓
MapKit calculates route
    ↓
MapViewModel.buildResultIfPossible()
    ↓
Identifies tolls near route polyline (350m threshold)
    ↓
Updates UI with tollsOnRoute
```

### 3. Toll Detection Algorithm

```
1. Get route polyline from MapKit
2. Sample points along polyline (every 25 points)
3. For each toll station:
   a. Get toll coordinates
   b. Calculate distance to each sample point
   c. If any distance ≤ 350m, include toll
4. Return filtered list of tolls on route
```

**Code Reference:**
```swift
private func tollsNearRoute(route: MKRoute, tolls: [Vegobjekt], maxDistanceMeters: Double) -> [Vegobjekt] {
    let polyline = route.polyline
    let routePoints = samplePolylinePoints(polyline, step: 25)

    return tolls.filter { toll in
        guard let c = toll.lokasjon?.coordinates else { return false }
        let tollLoc = CLLocation(latitude: c.latitude, longitude: c.longitude)

        for p in routePoints {
            let d = tollLoc.distance(from: CLLocation(latitude: p.latitude, longitude: p.longitude))
            if d <= maxDistanceMeters { return true }
        }
        return false
    }
}
```

---

## Installation

### Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Active Internet connection (for first launch to fetch toll data)

### Steps

1. Clone the repository:
```bash
git clone <repository-url>
cd toll-app
```

2. Open in Xcode:
```bash
open toll-app.xcodeproj
```

3. Update the X-Client header in `TollService.swift` with your email:
```swift
request.setValue("toll-app (your-email@example.com)", forHTTPHeaderField: "X-Client")
```

4. Build and run on simulator or device (Cmd+R)

### First Launch

The app will automatically:
1. Request location permissions
2. Fetch toll data from NVDB API (~500+ toll stations)
3. Save data locally with SwiftData
4. Be ready for offline use

---

## Usage

### Calculate a Route

1. Open the app
2. Tap the calculator icon in the tab bar
3. **From field**: 
   - Tap the location icon to use current location
   - Or tap the field to enter an address manually
4. **To field**: Tap to enter destination address
5. (Optional) Select date/time, vehicle type, fuel type, and Autopass status
6. Tap **"Calculate Route"**
7. View route on map with toll stations marked
8. See list of tolls on your route (price coming soon!)

### Use Nearby Tolls

1. In CalculatorView, scroll to "NEARBY TOLLS"
2. View toll stations sorted by distance from you
3. Tap any toll to auto-fill it as your destination
4. Calculate route to that toll

### View Recent Searches

Recent searches are automatically saved and can be accessed from the search views.

---

## 🔬 Technical Details

### SwiftData Integration

The app uses SwiftData for local persistence with the following models:
- `Vegobjekt` (toll stations)
- `Egenskap` (properties)
- `Lokasjon` (location)
- `Geometri` (geometry)
- `RecentSearch` (search history)

**ModelContainer setup:**
```swift
let modelContainer: ModelContainer = try! ModelContainer(for:
    Vegobjekt.self,
    Egenskap.self,
    Lokasjon.self,
    Geometri.self,
    RecentSearch.self
)
```

### Location Services

Uses `CLLocationManager` with:
- **Authorization**: `requestWhenInUseAuthorization()`
- **Accuracy**: `kCLLocationAccuracyBest`
- **Updates**: Continuous streaming with `startUpdatingLocation()`
- **Geocoding**: Converts coordinates to human-readable addresses

### MapKit Integration

- **Route Calculation**: `MKDirections` with automobile transport type
- **Map Rendering**: `Map` view with SwiftUI
- **Annotations**: Custom markers for tolls and user location
- **Camera Control**: Programmatic camera positioning to fit route bounds

### Performance Optimizations

1. **Toll Detection Sampling**: Instead of checking every point on the polyline, samples every 25th point to reduce calculations
2. **Local Caching**: SwiftData caches all toll data for offline use
3. **Monthly Updates**: Only fetches from API once per month to reduce bandwidth
4. **View Decomposition**: Complex SwiftUI views broken into smaller computed properties to avoid compiler timeouts

### Coordinate System

- **NVDB API**: Uses SRID (Spatial Reference System ID) with WKT format
- **App**: Converts to standard `CLLocationCoordinate2D` (latitude/longitude)
- **WKT Parsing**: Custom parser extracts coordinates from "POINT (lon lat)" format

---

## API Integration

### NVDB API Details

**Base URL:**
```
https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/
```

**Toll Stations Endpoint:**
```
/vegobjekter/45
```

**Object Type 45**: Toll stations ("Bomstasjoner")

**Response Format:**
```json
{
  "objekter": [
    {
      "id": 12345,
      "href": "https://nvdbapiles.atlas.vegvesen.no/vegobjekter/45/12345",
      "lokasjon": {
        "geometri": {
          "wkt": "POINT (10.7522 59.9139)",
          "srid": 4326
        }
      },
      "egenskaper": [
        {
          "id": 1,
          "navn": "Navn bomstasjon",
          "verdi": "Oslo City Toll"
        }
      ]
    }
  ]
}
```

### API Rate Limiting

The NVDB API requires a `X-Client` header for identification. Be respectful with API calls:
- App fetches data once at first launch
- Then only updates monthly
- Uses local cache for all operations

---

## Future Enhancements

### Priority Features

1. **Price Calculation** 🎯
   - Implement actual toll pricing based on:
     - Vehicle type (car vs motorcycle)
     - Fuel type (electric vs gas discounts)
     - Time of day (rush hour pricing)
     - Autopass status (discounts)
   - Requires additional API or pricing database

2. **Multiple Route Options**
   - Show alternative routes with different toll costs
   - "Avoid tolls" option
   - Cost vs time optimization

3. **Price History**
   - Track and display price changes over time
   - Help users choose optimal travel times

### Nice to Have

- **Payment Integration**: Pay tolls directly through the app
- **Notifications**: Remind users of toll stations ahead
- **Apple CarPlay**: Display tolls while driving
- **Widgets**: Show nearby tolls on home screen
- **Trip History**: Save and review past trips with costs

---

## Known Issues

1. **Price Calculation**: Currently returns $0 - waiting for pricing data/API
2. **350m Threshold**: Might miss tolls on complex interchanges or need tuning
3. **Geocoding Accuracy**: Depends on Apple's geocoding service quality
4. **First Launch**: Requires internet to download toll data (~500+ stations)

---

## Code Style

- **Architecture**: MVVM with SwiftUI
- **Concurrency**: Swift Concurrency (async/await) preferred over Dispatch/Combine
- **Comments**: Spanish comments in code (developer notes)
- **Naming**: Descriptive variable and function names
- **Error Handling**: Proper error types and throws

---

## License



---

## Credits

**Developer**: Carolina Mera

**Data Source**: NVDB (Norwegian Road Database) API
- Website: https://nvdbapiles.atlas.vegvesen.no/
- Organization: Norwegian Public Roads Administration

---

## Contact

For questions or support, contact: [carolinamera1985@gmail.com]

---

**Last Updated**: March 20, 2026
