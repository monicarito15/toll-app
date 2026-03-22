# Norwegian Toll Calculator

A SwiftUI-based iOS application for calculating toll costs on Norwegian routes using real-time pricing from the Bompenger API and toll station data from the NVDB API.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Technical Details](#technical-details)
- [API Integration](#api-integration)
- [Recent Updates](#recent-updates)
- [Known Issues](#known-issues)
- [Future Plans](#future-plans)
- [License](#license)
- [Contact](#contact)

---

## Overview

This app helps drivers in Norway plan their routes by calculating toll costs in advance. It combines toll station data from the NVDB (Norwegian Road Database) with real-time pricing from the Bompenger API. All data is cached locally using SwiftData for offline access and improved performance.

The app calculates routes using MapKit and identifies toll stations within 350 meters of your planned route, providing accurate pricing based on vehicle type, fuel type, travel time, and Autopass status.

**Current Status**: Fully functional with real-time pricing, navigation integration, and comprehensive route planning features.

---

## Features

### Route Planning and Navigation
- Calculate routes between any two addresses in Norway
- Automatic current location detection for quick route planning
- One-tap navigation using Apple Maps or Google Maps
- Quick access floating navigation button
- Accurate toll station detection (350m threshold)

### Pricing and Calculations
- Real-time toll pricing from Bompenger API
- 24-hour intelligent price caching to minimize API calls
- Local fallback pricing when offline
- Visual indicator for estimated vs real prices
- Support for different vehicle types (car, motorcycle)
- Electric vehicle discounts (approximately 40% off)
- Autopass holder discounts (approximately 20% off)
- Time-based pricing with rush hour detection

### User Interface
- Comprehensive toll summary bar showing all route details
- Rush hour indicator for peak travel times
- Vehicle type, fuel type, and Autopass status display
- Date and time selection for future trip planning
- Nearby toll stations list with distance calculations
- Search history for frequently used routes
- Detailed toll station information

### Data Management
- Local toll station data cache using SwiftData
- Automatic monthly updates of toll station database
- 24-hour price cache with smart invalidation
- Unique cache keys based on route parameters
- Offline toll detection capability

---

## Screenshots

*Screenshots will be added in a future update*

---

## Architecture

The application follows the MVVM (Model-View-ViewModel) pattern with SwiftUI and utilizes Swift Concurrency (async/await) throughout.

### High-Level Structure

```
Views Layer
├─ CalculatorView (route input and settings)
├─ MapView (map display with route and tolls)
├─ TollSummaryBar (pricing summary)
├─ NavigationFloatingButton (Apple/Google Maps integration)
├─ NearbyTolls (nearby toll stations)
└─ FromDirectionsView / ToDirectionsView (address search)

ViewModels Layer
├─ MapViewModel (route calculation, toll detection)
├─ FeeViewModel (price calculation and API calls)
├─ TollStorageViewModel (toll data management)
├─ FeeStorageViewModel (price cache management)
├─ SearchAddressViewModel (address search)
└─ LocationManager (location services)

Services and Data Layer
├─ TollService (NVDB API - toll stations)
├─ BompengerService (Bompenger API - pricing)
├─ TollPriceCalculator (local fallback pricing)
├─ SwiftData (local persistence)
├─ MapKit (routing)
└─ Core Location (user location)
```

---

## Installation

### Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Active internet connection (first launch and price updates)

### Configuration

#### 1. Bompenger API Key

You'll need to obtain an API key from the Bompenger API. Add it to your `Info.plist`:

```xml
<key>OCP_APIM_SUBSCRIPTION_KEY</key>
<string>YOUR_API_KEY_HERE</string>
```

#### 2. Google Maps URL Scheme

To enable Google Maps integration, add the URL scheme to `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>comgooglemaps</string>
</array>
```

#### 3. Location Permissions

Location permissions are already configured in the project's `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby toll stations and calculate routes.</string>
```

### Build and Run

1. Clone the repository:
```bash
git clone <repository-url>
cd toll-app
```

2. Open the project in Xcode:
```bash
open toll-app.xcodeproj
```

3. Add your Bompenger API key to `Info.plist`

4. Build and run the project (Cmd+R)

### First Launch

On first launch, the app will:
1. Request location permissions from the user
2. Fetch toll station data from the NVDB API (approximately 500 stations)
3. Save the data locally with SwiftData
4. Be ready for offline toll detection
5. Fetch prices from the Bompenger API as needed

---

## Usage

### Calculating a Route

1. Open the app and tap the calculator icon in the tab bar
2. Enter your starting point:
   - Tap the location icon to use your current location
   - Or tap the field to manually enter an address
3. Enter your destination address in the "To" field
4. Configure your trip settings:
   - Select vehicle type (Car or Motorcycle)
   - Select fuel type (Gas or Electric)
   - Choose the date and time of travel
   - Toggle Autopass status if applicable
5. Tap "Calculate Route"
6. View the route on the map with toll stations marked
7. See the pricing summary at the top showing:
   - Total number of tolls on your route
   - Total estimated cost
   - Vehicle, fuel, and Autopass details
   - Rush hour indicator (if applicable)
8. Tap the navigation button in the bottom-right corner to start turn-by-turn directions

### Navigation Options

After calculating a route, tap the blue navigation button to choose:
- **Apple Maps**: Opens directly with driving directions
- **Google Maps**: Opens the app if installed, otherwise uses the web version

### Understanding Prices

The app displays two types of prices:

**Real Prices**: Fetched directly from the Bompenger API. These are the most accurate and reflect current toll rates.

**Estimated Prices**: Calculated locally using average toll costs. These are shown with a warning icon (triangle with exclamation mark) and the text "est." They appear when:
- No internet connection is available
- The API returns an error
- Coordinates are missing for the route

### Price Factors

Your total toll cost is affected by:
- **Vehicle Type**: Cars typically pay more than motorcycles
- **Fuel Type**: Electric vehicles receive approximately 40% discount
- **Autopass**: Members save approximately 20% on tolls
- **Time of Day**: Rush hour pricing applies during peak periods (weekday mornings 6:30-9:00 and afternoons 15:00-17:00)
- **Route**: Number and type of tolls on your specific route

The app automatically detects rush hour times based on your selected travel date and time, displaying an indicator in the toll summary bar when applicable.

---

## Technical Details

### Core Components

#### FeeViewModel

Handles all price calculation logic and API integration.

**Responsibilities:**
- Calls Bompenger API for real-time pricing
- Manages 24-hour price cache
- Handles API failures with local calculations
- Applies discounts for vehicle/fuel/Autopass
- Tracks whether prices are estimated or real

**Key Method:**
```swift
func loadOrCalculateFees(
    tollsOnRoute: [Vegobjekt],
    from: String,
    to: String,
    vehicle: VehicleType,
    fuel: FuelType,
    date: Date,
    modelContext: ModelContext,
    storage: FeeStorageViewModel,
    originCoordinate: CLLocationCoordinate2D?,
    destinationCoordinate: CLLocationCoordinate2D?
)
```

#### MapViewModel

Manages routing and toll detection.

**Responsibilities:**
- Calculates routes using MapKit
- Manages toll station data
- Tracks user location
- Detects tolls within 350 meters of routes

**Toll Detection Algorithm:**
1. Samples points along the route polyline (every 25th point)
2. For each toll station, calculates distance to sample points
3. Includes toll if any distance is less than or equal to 350 meters
4. Returns filtered list of tolls on the route

#### NavigationFloatingButton

Provides quick access to navigation apps.

**Features:**
- Floating action button design
- Dialog for choosing navigation app
- Apple Maps integration with driving directions
- Google Maps integration (app or web fallback)
- Modern rounded square design

### API Integration

#### Bompenger API

**Endpoint**: `https://dibkunnskapapi.azure-api.net/vCustomer/api/bomstasjoner/GetFeesByWaypoints`

**Request Parameters:**
- Origin and destination coordinates
- Date and time of travel (YYYYMMDD and HHMM format)
- Vehicle size (1 for small vehicles, 2 for large)
- Fuel type (note: the API has inverted values - 1 is electric, 2 is gas)
- Round trip indicator
- Time reference flag

**Response Fields:**
- `Kostnad`: Total price without Autopass
- `Rabattert`: Total price with Autopass discount

**Important Note**: The API documentation lists fuel types in reverse. The app handles this with an inverted logic flag.

**Caching Strategy:**
- Prices are cached for 24 hours
- Cache keys include route, vehicle, fuel, time, and Autopass status
- Expired cache triggers new API call
- API failures fall back to local calculation

#### NVDB API

**Endpoint**: `https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45`

**Object Type 45**: Toll stations ("Bomstasjoner")

**Update Frequency**: Monthly automatic updates

The NVDB API provides comprehensive toll station data including precise coordinates, station names, and regional information. The data is stored locally using SwiftData for offline access.

### SwiftData Models

**Toll Data:**
- `Vegobjekt`: Toll station objects
- `Egenskap`: Station properties
- `Lokasjon`: Location data
- `Geometri`: Geographic geometry

**User Data:**
- `RecentSearch`: Recent search history
- `SearchHistoryItem`: Detailed search records with settings

**Price Cache:**
- `FeeCalculation`: 24-hour price cache with expiration tracking

### Performance Optimizations

**Smart Caching:**
- Toll station data updates monthly
- Price cache valid for 24 hours
- Unique cache keys prevent unnecessary API calls

**Efficient Toll Detection:**
- Samples every 25th point on route polyline
- Reduces distance calculations by approximately 96%

**Asynchronous Operations:**
- All network calls use async/await
- Non-blocking UI during data fetching

**View Optimization:**
- Complex views decomposed into smaller components
- Lazy loading where appropriate

---

## API Integration

### Price Calculation Flow

```
User calculates route
    ↓
MapViewModel identifies tolls on route (350m threshold)
    ↓
FeeViewModel.loadOrCalculateFees() triggered
    ↓
Check local cache (24h validity)
    ↓
If cache exists and valid → Use cached price
    ↓
If cache expired or missing → Call Bompenger API
    ↓
If API succeeds → Use real price, save to cache
    ↓
If API fails → Use local calculation, mark as estimated
```

### Route Calculation Flow

```
User enters addresses
    ↓
Geocode addresses to coordinates
    ↓
Calculate route with MapKit
    ↓
Sample route polyline points
    ↓
Identify tolls within 350m
    ↓
Trigger price calculation
    ↓
Display results with navigation option
```

---



## Known Issues

1. **Price Accuracy**: Fallback prices are estimates based on average toll costs. Actual prices may vary and should be verified when internet connection is available.

2. **API Dependency**: Real-time prices require an active internet connection and valid Bompenger API key.

3. **Detection Threshold**: The 350-meter threshold may occasionally miss tolls on complex highway interchanges or include tolls on nearby parallel routes.

4. **First Launch Requirement**: Initial launch requires internet connection to download the toll station database (approximately 500 stations).

---

## Future Plans

### Planned Features


**Price History**
- Track and display toll price changes over time
- Historical pricing charts
- Recommendations for optimal travel times

**Trip Planning**
- Multi-stop route planning
- Round-trip pricing calculations
- Save and manage favorite routes


### Additional Ideas

- Notifycations
- Push notifications for toll station proximity

---

## License

MIT License

Copyright (c) 2026 Carolina Mera

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
