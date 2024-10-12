//
//  Map.swift
//  My Map
//
//  Created by Anthony on 7/26/24.
//

import MapKit
import SwiftUI
import CoreLocation
import Foundation
import SwiftData

struct MapView: View {    
    @ObservedObject var sharedList: SharedList
    @Binding var mapStyle: MapStyle
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var position: MapCameraPosition = .region(.init(center: CLLocationCoordinate2D(latitude: 47.308013, longitude: -122.134067), span: MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)))
    
    var body: some View {
        MapReader { MapProxy in
            Map (position: $position, interactionModes: .all) {
                ForEach (sharedList.layerList) { locationList in
                    ForEach(locationList.locations) { marker in
                        Marker(marker.name, coordinate: marker.coordinate)
                    }
                }
            }
            .mapStyle(.hybrid)
            .ignoresSafeArea()
        }
    }
}


struct LocationLayer: Identifiable, Encodable, Decodable {
    init(name: String, locations: [Location]) {
        self.name = name
        self.locations = locations
    }
    
    init() {
        name = ""
        locations = [Location]()
    }
    
    private enum CodingKeys: CodingKey {
        case name, locations
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(locations,
                             forKey: .locations)
        
    }
    
    let id: UUID = UUID()
    var name: String
    var locations: [Location]
}

struct Location: Identifiable, Encodable, Decodable {
    init(name: String, desc: String, layer: String, lati: Double, long: Double, icon: String) {
        self.name = name
        self.desc = desc
        self.layer = layer
        self.lati = lati
        self.long = long
        self.icon = icon
    }
    init() {
        name = ""
        desc = ""
        layer = ""
        lati = 0
        long = 0
        icon = ""
//        coordinate = nil
    }
    
    private enum CodingKeys: CodingKey {
        case name, desc, layer, lati, long, icon
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(desc,
                             forKey: .desc)
        try container.encode(layer,
                             forKey: .layer)
        try container.encode(lati, forKey: .lati)
        try container.encode(long, forKey: .long)
        try container.encode(icon, forKey: .icon)
    }
    
//    mutating func setCoords() {
//        self.coordinate = CLLocationCoordinate2D(latitude: lati, longitude: long)
//    }
    
    let id: UUID = UUID()
    var name: String
    var desc: String
    var layer: String
    var lati: Double
    var long: Double
    var icon: String
//    var coordinate: CLLocationCoordinate2D?
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lati, longitude: long)
    }
}
