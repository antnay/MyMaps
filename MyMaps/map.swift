//
//  Map.swift
//  My Map
//
//  Created by Anthony on 7/26/24.
//

import MapKit
import SwiftUI
import CoreLocation

struct MapView: View {
    @State private var position = MapCameraPosition.automatic
    
    var body: some View {
        Map(position: $position)
            .mapStyle(.hybrid)
            .ignoresSafeArea()
    }
}


