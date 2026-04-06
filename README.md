# TollTrack

Norwegian toll calculator for iOS. Enter an origin and destination, and the app shows every toll station on your route with real-time prices — so you know the cost before you drive.

---

## Features

- Real-time toll pricing from the Bompenger API
- Route calculation with toll station detection (150m threshold)
- Rush hour surcharge detection (weekdays 06:30-09:00 and 15:00-17:00)
- Vehicle type support: car and motorcycle
- Fuel type support: petrol, diesel, and electric (approx. 40% discount)
- Autopass holder discount (approx. 20% off)
- 24-hour price cache with offline fallback and estimated price indicator
- Monthly automatic refresh of toll station data from NVDB
- Search history stored locally on device
- One-tap navigation via Apple Maps or Google Maps

---

## Requirements

- iOS 18.5 or later
- Xcode 16 or later
- Bompenger API key (`OCP_APIM_SUBSCRIPTION_KEY`)

---

## Setup

1. Clone the repository and open `toll-app.xcodeproj` in Xcode.
2. Create a `Secrets.xcconfig` file at the project root with your API key:
   ```
   OCP_APIM_SUBSCRIPTION_KEY = your_key_here
   ```
3. Build and run (Cmd+R).

On first launch the app downloads approximately 500 toll stations from NVDB and saves them locally. An internet connection is required for this initial load and for real-time pricing.

---

## Architecture

MVVM with SwiftUI and async/await throughout. No Combine.

```
Views
├── TravelView
├── MapView
├── CalculatorView
├── TollSummaryBarView
├── TollPassedListView
├── HistoryView
└── SettingsView

ViewModels
├── MapViewModel       — route calculation, toll detection
├── FeeViewModel       — pricing, cache, API calls
├── TollStorageViewModel — toll data (SwiftData)
├── FeeStorageViewModel  — price cache (SwiftData)
└── SearchAddressViewModel

Services
├── TollService        — NVDB API
├── BompengerService   — Bompenger pricing API
└── LocationManager    — Core Location
```

---

## External APIs

**NVDB** (`nvdbapiles.atlas.vegvesen.no`)
Toll station locations. Returns UTM coordinates (SRID 5973), converted to WGS84 via ArcGIS SDK. Updated monthly.

**Bompenger** (`dibkunnskapapi.azure-api.net`)
Real-time toll pricing. Requires API key passed via `Info.plist`. Prices cached for 24 hours; API failures fall back to local estimated pricing.

---

## Price Calculation Flow

```
User submits route
    → MapKit calculates polyline
    → Sample every 10th polyline point
    → Identify toll stations within 150m
    → Check 24h price cache
    → Cache hit: use cached price
    → Cache miss: call Bompenger API
    → API success: save to cache, display real price
    → API failure: calculate locally, display as estimated
```

---

## Known Limitations

- Fallback (estimated) prices are based on average toll costs and may not match actual rates.
- The 150m detection threshold may miss tolls on complex interchanges or include tolls on nearby parallel roads.
- Real-time prices require an active internet connection and a valid Bompenger API key.
- First launch requires internet to download the toll station database.

---

## License

MIT License — Copyright (c) 2026 Carolina Mera
