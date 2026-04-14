# TollTrack

Norwegian toll calculator for iOS. Enter an origin and destination, and the app shows every toll station on your route with real-time prices — so you know the cost before you drive.

---

## Features

- Real-time toll pricing from the Bompenger API
- Multiple alternative routes (up to 3) via OSRM and MapKit
- Directional toll filtering — only charges the correct direction (nordgående/sørgående)
- Rush hour surcharge detection (weekdays 06:30–09:00 and 15:00–17:00)
- Vehicle type support: car and motorcycle
- Fuel type support: petrol, diesel, and electric (50% discount)
- Autopass toggle
- 24-hour price cache with offline fallback and estimated price indicator
- Monthly automatic refresh of toll station data from NVDB
- Search history stored locally on device
- Recent address suggestions
- Nearby toll stations browser
- One-tap navigation via Apple Maps or Google Maps
- Dark mode support

---

## Pricing

- **Free:** 10 route searches per month
- **Unlimited:** 19 kr one-time purchase (StoreKit 2)

---

## Requirements

- iOS 18.5 or later
- Xcode 16 or later

---

## Setup

1. Clone the repository and open `toll-app.xcodeproj` in Xcode.
2. Build and run (Cmd+R).

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
├── FromDirectionsView
├── ToDirectionsView
└── SettingsView

ViewModels
├── MapViewModel          — route calculation, toll detection, directional filtering
├── FeeViewModel          — pricing, cache, API calls
├── TollStorageViewModel  — toll data (SwiftData)
├── FeeStorageViewModel   — price cache (SwiftData)
└── SearchAddressViewModel — address autocomplete, recent searches

Services
├── TollService           — NVDB API
├── OSRMService           — OpenStreetMap routing (alternative routes)
└── LocationManager       — Core Location

Store
├── PurchaseManager       — StoreKit 2, free limit, monthly reset
└── PaywallView
```

---

## External APIs

**NVDB** (`nvdbapiles.atlas.vegvesen.no`)
Toll station locations and pricing data. Returns UTM coordinates (SRID 5973), converted to WGS84 via ArcGIS SDK. Updated monthly. No API key required.

**OSRM** (`router.project-osrm.org`)
OpenStreetMap-based routing. Returns up to 3 real alternative routes. Falls back to MapKit if unavailable. No API key required.

---

## Price Calculation Flow

```
User submits route
    → OSRM + MapKit calculate alternative polylines
    → Perpendicular distance check for each toll station (50m threshold)
    → Directional filter (nordgående/sørgående/østgående/vestgående)
    → Prices calculated from NVDB toll data (takst, rushtidstakst)
    → Results cached for 24 hours
```

---

## Known Limitations

- Prices are based on NVDB data and may not reflect temporary rate changes.
- First launch requires internet to download the toll station database.

---

## License

MIT License — Copyright (c) 2026 Carolina Mera
