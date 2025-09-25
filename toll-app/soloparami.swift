//
//  soloparami.swift
//  toll-app
//
//  Created by Carolina Mera  on 25/09/2025.
//

/*
MainTabView
+-----------------------------+
| @State currentDetent        |  ← Origen del tamaño del sheet
| @State showSheet            |
|                             |
| TabView                     |
| └─ SearchView               |
|     @Binding currentDetent   ← recibe binding del padre
|     @Binding showSheet
|     └─ sheet → CalculatorView
|          @Binding currentDetent   ← comparte el mismo binding
|          @State showToDirections
|          └─ sheet → ToDirectionsView
|               @Binding currentDetent   ← mismo binding
|               @Binding searchText


*/
