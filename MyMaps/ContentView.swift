//
//  ContentView.swift
//  My Map
//
//  Created by Anthony on 7/26/24.
//

import SwiftUI
import MapKit

// TODO: Weather and other water conditions for certain areas, weather can be like apple map thing

struct ContentView: View {
    //     TODO: inital location at user location
    @State private var search:String = ""
    
    var body: some View {
        ZStack {
            MapView()
            
            DoubleButton(
                topButtonImageName: "globe.americas.fill",
                bottomButtonImageName:  "location") { tappedButton in
                    switch tappedButton {
                    case .top:
                        // TODO: Sheet popups and choose
                        // TODO: choose explore or satelite or hybrid/terrain IDK
                        print("top button tapped")
                    case .bottom:
                        // TODO: Snap to current location
                        print("bottom button tapped")
                        getKMZ()
                    }
                }
                .position(x:UIScreen.main.bounds.width - 30, y:UIScreen.main.bounds.minY + 110)
            OuterDrawerView()
        }
        .edgesIgnoringSafeArea(.vertical)
    }
    
}

#Preview {
    ContentView()
}
