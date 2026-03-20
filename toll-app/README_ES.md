# Toll App - Calculadora de Peajes de Noruega

Una aplicación iOS basada en SwiftUI que calcula los costos de peajes para rutas en Noruega utilizando datos en tiempo real de la API NVDB (Base de Datos de Carreteras de Noruega).

## Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Características](#características)
- [Arquitectura](#arquitectura)
- [Componentes Principales](#componentes-principales)
- [Flujo de Datos](#flujo-de-datos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Detalles Técnicos](#detalles-técnicos)
- [Integración con API](#integración-con-api)

---

## Descripción General

Esta aplicación ayuda a los conductores en Noruega a calcular los costos de peaje para sus rutas. Obtiene datos de estaciones de peaje desde la API NVDB, los almacena localmente usando SwiftData para acceso sin conexión, y calcula rutas usando MapKit para identificar qué estaciones de peaje están en el camino.

**Estado Actual**: La aplicación identifica exitosamente las estaciones de peaje en una ruta, pero el cálculo de precios aún no está implementado (devuelve $0).

---

## Características

### Implementadas

- **Cálculo de Rutas**: Calcula rutas entre dos direcciones usando MapKit
- **Integración de Ubicación Actual**: Detecta y usa automáticamente tu ubicación actual como punto de partida
- **Detección de Estaciones de Peaje**: Identifica estaciones de peaje dentro de 350 metros de tu ruta calculada
- **Soporte Sin Conexión**: Datos de peaje almacenados localmente usando SwiftData
- **Historial de Búsquedas**: Guarda búsquedas recientes para acceso rápido
- **Peajes Cercanos**: Muestra estaciones de peaje cerca de tu ubicación actual
- **Selección de Tipo de Vehículo y Combustible**: Elige entre carro/motocicleta y gasolina/eléctrico
- **Selección de Fecha y Hora**: Selecciona cuándo viajarás
- **Toggle de Autopass**: Indica si tienes una cuenta Autopass

### 🚧 En Desarrollo

- **Cálculo de Precios**: Calcular costos reales de peaje basados en tipo de vehículo, tipo de combustible, hora y estado de Autopass
- **Rutas Alternativas**: Mostrar múltiples opciones de ruta con diferentes costos de peaje

---

## Arquitectura

La aplicación sigue el patrón de arquitectura MVVM (Model-View-ViewModel) con SwiftUI y Swift Concurrency (async/await).

```
┌─────────────────────────────────────────────────────────────┐
│                          Vistas                              │
│  (CalculatorView, NearbyTolls, TollMapView, etc.)          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModels                              │
│  • MapViewModel (cálculo de rutas, detección de peajes)    │
│  • TollStorageViewModel (gestión de datos locales)         │
│  • LocationManager (servicios de ubicación)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Servicios y Datos                           │
│  • TollService (llamadas a API)                             │
│  • SwiftData (persistencia local)                           │
│  • MapKit (enrutamiento)                                    │
└─────────────────────────────────────────────────────────────┘
```

---

##  Componentes Principales

### Vistas

#### `CalculatorView`
La interfaz principal para el cálculo de rutas.

**Características:**
- Campos de entrada de dirección Desde/Hasta
- Botón de ubicación actual con geocodificación
- Selector de fecha/hora para planificación de viaje
- Selectores de tipo de vehículo y combustible
- Toggle de Autopass
- Lista de peajes cercanos con funcionalidad de tocar para seleccionar

**Aspectos Destacados del Código:**
```swift
// Estructura del body simplificada (refactorizada para evitar timeout del compilador)
var body: some View {
    NavigationView {
        ScrollView {
            VStack(spacing: 20) {
                routeAndTimeSection      // Entradas Desde/Hasta/Fecha
                vehicleDetailsSection    // Vehículo/Combustible/Autopass
                calculateButton          // Acción calcular ruta
                nearbyTollsSection       // Estaciones de peaje cercanas
            }
        }
    }
}
```

#### `NearbyTolls`
Muestra una lista de estaciones de peaje cerca de la ubicación actual del usuario.

**Características:**
- Cálculo de distancia desde el usuario al peaje
- Ordenamiento por más cercano primero
- Tocar para auto-completar destino en CalculatorView

#### `TollMapView`
Muestra el mapa con ruta, marcadores de peaje y ubicación del usuario.

**Características:**
- Mapa interactivo con superposición de ruta
- Anotaciones de estaciones de peaje
- Auto-zoom para ajustar límites de ruta
- Gestión de posición de cámara

---

### ViewModels

#### `MapViewModel`
El cerebro de la aplicación - maneja enrutamiento, detección de peajes y gestión de ubicación.

**Responsabilidades Clave:**
- Cálculo de rutas usando MapKit
- Gestión de datos de estaciones de peaje
- Seguimiento de ubicación del usuario
- Detección de peajes a lo largo de rutas

**Métodos Importantes:**
```swift
// Calcula ruta entre dos coordenadas
func getDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async

// Geocodifica direcciones a coordenadas, luego calcula ruta
func getDirectionsFromAddresses(fromAddress: String, toAddress: String) async

// Identifica peajes dentro de 350m de la ruta
func buildResultIfPossible(vehicle: VehicleType, fuel: FuelType, date: Date)

// Filtra peajes cerca de la polilínea de ruta
private func tollsNearRoute(route: MKRoute, tolls: [Vegobjekt], maxDistanceMeters: Double) -> [Vegobjekt]
```

**Propiedades Publicadas:**
```swift
@Published var route: MKRoute?                        // Ruta calculada
@Published var toll: [Vegobjekt] = []                 // Todas las estaciones de peaje
@Published var userLocation: CLLocationCoordinate2D?  // Ubicación del usuario
@Published var hasResult: Bool = false                // Mostrar barra de resultados
@Published var tollsOnRoute: [Vegobjekt] = []         // Peajes en ruta actual
@Published var totalPrice: Double = 0                 // Costo total (actualmente 0)
```

#### `TollStorageViewModel`
Gestiona la persistencia de datos de peaje locales usando SwiftData.

**Responsabilidades Clave:**
- Cargar peajes desde base de datos local
- Obtener de API si los datos locales están vacíos
- Actualizaciones mensuales automáticas (verifica si los datos tienen más de 1 mes)
- Sincronización de datos

**Métodos Importantes:**
```swift
// Carga peajes desde SwiftData, obtiene de API si está vacío
func loadTolls(using modelContext: ModelContext) async

// Obtiene de API y guarda en SwiftData
private func fetchAndSaveFromApi(using modelContext: ModelContext) async throws

// Verifica si debemos actualizar desde API (> 1 mes de antigüedad)
func shouldUpdateFromAPI() -> Bool

// Actualiza peajes si es necesario y guarda fecha de actualización
func updateTollsIfNeeded(using modelContext: ModelContext) async
```

#### `LocationManager`
Maneja toda la funcionalidad de Core Location.

**Características:**
- Actualizaciones de ubicación en tiempo real
- Gestión de estado de autorización
- Geocodificación inversa (coordenadas → dirección)
- Solicitudes de ubicación de una sola vez

**Propiedades Publicadas:**
```swift
@Published var userLocation: CLLocationCoordinate2D?
@Published var authorizationStatus: CLAuthorizationStatus?
@Published var currentAddress: String?
```

---

### Servicios

#### `TollService`
Cliente API para NVDB (Base de Datos de Carreteras de Noruega).

**Endpoint de API:**
```
https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/vegobjekter/45
```

**Parámetros:**
- `inkluder=lokasjon` - Incluir datos de ubicación
- `inkluder=egenskaper` - Incluir propiedades (nombre, etc.)

**Encabezados:**
```swift
Accept: application/json
X-Client: toll-app (carolina.m@gmail.com)
```

**Método Clave:**
```swift
func getTolls() async throws -> [Vegobjekt]
```

**Manejo de Errores:**
```swift
enum GHError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}
```

---

### Modelos

#### `Vegobjekt` (Estación de Peaje)
Modelo principal de estación de peaje almacenado en SwiftData.

**Propiedades:**
- `id: Int` - Identificador único
- `href: String` - URL de referencia de API
- `egenskaper: [Egenskap]` - Propiedades (nombre, etc.)
- `lokasjon: Lokasjon?` - Ubicación geográfica

#### `Egenskap` (Propiedad)
Propiedades clave-valor de una estación de peaje.

**Propiedades:**
- `id: Int`
- `navn: String` - Nombre de propiedad (ej., "Navn bomstasjon")
- `verdi: String?` - Valor de propiedad (ej., "Estación de Peaje Oslo")

#### `Lokasjon` (Ubicación)
Datos de ubicación geográfica.

**Propiedades:**
- `geometri: Geometri` - Datos de geometría

**Propiedad Computada:**
```swift
var coordinates: CLLocationCoordinate2D? {
    // Analiza formato WKT: "POINT (10.7522 59.9139)"
    // Devuelve CLLocationCoordinate2D
}
```

#### `Geometri` (Geometría)
Datos geográficos crudos de NVDB.

**Propiedades:**
- `wkt: String` - Formato Well-Known Text (ej., "POINT (10.7522 59.9139)")
- `srid: Int` - ID de Sistema de Referencia Espacial

#### `RecentSearch`
Historial de búsquedas del usuario almacenado en SwiftData.

**Propiedades:**
- `name: String` - Nombre de búsqueda
- `address: String` - Dirección completa
- `createdAt: Date` - Cuándo se guardó
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

##  Flujo de Datos

### 1. Inicio de Aplicación

```
toll_appApp.swift
    ↓
Crea ModelContainer con modelos SwiftData
    ↓
Carga MainTabView con modelContainer inyectado
    ↓
TollStorageViewModel verifica datos locales
    ↓
Si está vacío: Obtener de API NVDB
    ↓
Guardar en SwiftData para acceso sin conexión
```

### 2. Cálculo de Ruta

```
Usuario ingresa direcciones en CalculatorView
    ↓
Toca "Calculate Route"
    ↓
MapViewModel.getDirectionsFromAddresses()
    ↓
Geocodifica direcciones a coordenadas
    ↓
MapViewModel.getDirections()
    ↓
MapKit calcula ruta
    ↓
MapViewModel.buildResultIfPossible()
    ↓
Identifica peajes cerca de polilínea de ruta (umbral de 350m)
    ↓
Actualiza UI con tollsOnRoute
```

### 3. Algoritmo de Detección de Peajes

```
1. Obtener polilínea de ruta de MapKit
2. Muestrear puntos a lo largo de polilínea (cada 25 puntos)
3. Para cada estación de peaje:
   a. Obtener coordenadas del peaje
   b. Calcular distancia a cada punto de muestra
   c. Si alguna distancia ≤ 350m, incluir peaje
4. Devolver lista filtrada de peajes en ruta
```

**Referencia de Código:**
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

## Instalación

### Requisitos

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Conexión a Internet activa (para primer inicio para obtener datos de peaje)

### Pasos

1. Clonar el repositorio:
```bash
git clone <repository-url>
cd toll-app
```

2. Abrir en Xcode:
```bash
open toll-app.xcodeproj
```

3. Actualizar el encabezado X-Client en `TollService.swift` con tu correo:
```swift
request.setValue("toll-app (tu-email@ejemplo.com)", forHTTPHeaderField: "X-Client")
```

4. Compilar y ejecutar en simulador o dispositivo (Cmd+R)

### Primer Inicio

La aplicación automáticamente:
1. Solicitará permisos de ubicación
2. Obtendrá datos de peaje de API NVDB (~500+ estaciones de peaje)
3. Guardará datos localmente con SwiftData
4. Estará lista para uso sin conexión

---

## Uso

### Calcular una Ruta

1. Abre la aplicación
2. Toca el ícono de calculadora en la barra de pestañas
3. **Campo Desde**: 
   - Toca el ícono de ubicación para usar ubicación actual
   - O toca el campo para ingresar una dirección manualmente
4. **Campo Hasta**: Toca para ingresar dirección de destino
5. (Opcional) Selecciona fecha/hora, tipo de vehículo, tipo de combustible y estado de Autopass
6. Toca **"Calculate Route"**
7. Ver ruta en mapa con estaciones de peaje marcadas
8. Ver lista de peajes en tu ruta (¡precio próximamente!)

### Usar Peajes Cercanos

1. En CalculatorView, desplázate a "NEARBY TOLLS"
2. Ver estaciones de peaje ordenadas por distancia desde ti
3. Toca cualquier peaje para auto-completarlo como tu destino
4. Calcula ruta a ese peaje

### Ver Búsquedas Recientes

Las búsquedas recientes se guardan automáticamente y se pueden acceder desde las vistas de búsqueda.

---

##  Detalles Técnicos

### Integración con SwiftData

La aplicación usa SwiftData para persistencia local con los siguientes modelos:
- `Vegobjekt` (estaciones de peaje)
- `Egenskap` (propiedades)
- `Lokasjon` (ubicación)
- `Geometri` (geometría)
- `RecentSearch` (historial de búsqueda)

**Configuración de ModelContainer:**
```swift
let modelContainer: ModelContainer = try! ModelContainer(for:
    Vegobjekt.self,
    Egenskap.self,
    Lokasjon.self,
    Geometri.self,
    RecentSearch.self
)
```

### Servicios de Ubicación

Usa `CLLocationManager` con:
- **Autorización**: `requestWhenInUseAuthorization()`
- **Precisión**: `kCLLocationAccuracyBest`
- **Actualizaciones**: Streaming continuo con `startUpdatingLocation()`
- **Geocodificación**: Convierte coordenadas a direcciones legibles

### Integración con MapKit

- **Cálculo de Rutas**: `MKDirections` con tipo de transporte automóvil
- **Renderizado de Mapa**: Vista `Map` con SwiftUI
- **Anotaciones**: Marcadores personalizados para peajes y ubicación del usuario
- **Control de Cámara**: Posicionamiento programático de cámara para ajustar límites de ruta

### Optimizaciones de Rendimiento

1. **Muestreo de Detección de Peajes**: En lugar de verificar cada punto en la polilínea, muestrea cada 25º punto para reducir cálculos
2. **Caché Local**: SwiftData almacena todos los datos de peaje para uso sin conexión
3. **Actualizaciones Mensuales**: Solo obtiene de API una vez al mes para reducir ancho de banda
4. **Descomposición de Vistas**: Vistas complejas de SwiftUI divididas en propiedades computadas más pequeñas para evitar timeouts del compilador

### Sistema de Coordenadas

- **API NVDB**: Usa SRID (ID de Sistema de Referencia Espacial) con formato WKT
- **Aplicación**: Convierte a `CLLocationCoordinate2D` estándar (latitud/longitud)
- **Análisis WKT**: Analizador personalizado extrae coordenadas del formato "POINT (lon lat)"

---

## Integración con API

### Detalles de API NVDB

**URL Base:**
```
https://nvdbapiles.atlas.vegvesen.no/vegobjekter/api/v4/
```

**Endpoint de Estaciones de Peaje:**
```
/vegobjekter/45
```

**Tipo de Objeto 45**: Estaciones de peaje ("Bomstasjoner")

**Formato de Respuesta:**
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
          "verdi": "Peaje Ciudad Oslo"
        }
      ]
    }
  ]
}
```

### Limitación de Tasa de API

La API NVDB requiere un encabezado `X-Client` para identificación. Sé respetuoso con las llamadas a API:
- La aplicación obtiene datos una vez en el primer inicio
- Luego solo actualiza mensualmente
- Usa caché local para todas las operaciones

---

##  Mejoras Futuras

### Características Prioritarias

1. **Cálculo de Precios** 🎯
   - Implementar precios reales de peaje basados en:
     - Tipo de vehículo (carro vs motocicleta)
     - Tipo de combustible (descuentos para eléctricos vs gasolina)
     - Hora del día (precios en hora pico)
     - Estado de Autopass (descuentos)
   - Requiere API adicional o base de datos de precios

2. **Múltiples Opciones de Ruta**
   - Mostrar rutas alternativas con diferentes costos de peaje
   - Opción "Evitar peajes"
   - Optimización de costo vs tiempo

3. **Historial de Precios**
   - Rastrear y mostrar cambios de precio con el tiempo
   - Ayudar a usuarios a elegir momentos óptimos de viaje

### Características Deseables

- **Integración de Pagos**: Pagar peajes directamente a través de la aplicación
- **Notificaciones**: Recordar a usuarios de estaciones de peaje adelante
- **Apple CarPlay**: Mostrar peajes mientras se conduce
- **Widgets**: Mostrar peajes cercanos en pantalla de inicio
- **Historial de Viajes**: Guardar y revisar viajes pasados con costos

---

##  Problemas Conocidos

1. **Cálculo de Precios**: Actualmente devuelve $0 - esperando datos/API de precios
2. **Umbral de 350m**: Podría perder peajes en intercambios complejos o necesitar ajuste
3. **Precisión de Geocodificación**: Depende de la calidad del servicio de geocodificación de Apple
4. **Primer Inicio**: Requiere internet para descargar datos de peaje (~500+ estaciones)

---

## Estilo de Código

- **Arquitectura**: MVVM con SwiftUI
- **Concurrencia**: Swift Concurrency (async/await) preferido sobre Dispatch/Combine
- **Comentarios**: Comentarios en español en código (notas del desarrollador)
- **Nomenclatura**: Nombres de variables y funciones descriptivos
- **Manejo de Errores**: Tipos de error apropiados y throws

---

## Licencia



---

## Créditos

**Desarrolladora**: Carolina Mera

**Fuente de Datos**: API NVDB (Base de Datos de Carreteras de Noruega)
- Sitio web: https://nvdbapiles.atlas.vegvesen.no/
- Organización: Administración Pública de Carreteras de Noruega

---

##  Contacto

Para preguntas o soporte, contactar: [carolinamera1985@gmail.com]

---

**Última Actualización**: 20 de Marzo, 2026
