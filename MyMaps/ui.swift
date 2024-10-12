//
//  UI.swift
//  My Map
//
//  Created by Anthony on 7/26/24.
//

// TODO: locations should have option to open in maps or google maps for routing
// TODO: Display description too
// TODO: Recent locations

import SwiftUI
import UIKit
import Drawer
import UniformTypeIdentifiers

struct DoubleButton: View {
    var topButtonImageName: String
    var bottomButtonImageName: String
    var buttonTapped: (ButtonType) -> ()
    enum ButtonType {
        case top
        case bottom
    }
    var body: some View {
        VStack(spacing: 0.0) {
            button(buttonType: .top, imageName: topButtonImageName)
            Color.gray.frame(height: 0.5)
            button(buttonType: .bottom, imageName: bottomButtonImageName)
        }
        .frame(width: 40.0, height: 85)
        .background {
            Color(UIColor.systemGray5)
                .cornerRadius(5.0)
                .shadow(color: .gray, radius:40, x: 0.0, y: 0.0)
        }
    }
    
    func button(buttonType: ButtonType, imageName: String) -> some View {
        return Button(action: {
            buttonTapped(buttonType)
        }, label: {
            Image(systemName: imageName)
                .foregroundStyle(Color(UIColor.systemGray))
                .font(.system(size: 20))
        })
        .padding(9)
        .foregroundColor(.gray)
    }
}

struct OuterDrawerView: View {    
    @ObservedObject var sharedList: SharedList

    var body: some View {
        Drawer(startingHeight:350) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color(UIColor.systemGray5))
                    .shadow(radius: 100)
                VStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 3.0)
                        .foregroundColor(Color(UIColor.systemGray))
                        .frame(width: 40.0, height: 6.0)
                        .padding(.top, 7)
                    DrawerView(sharedList: sharedList)
                    //                    Spacer()
                }
            }
        }
        .rest(at: .constant([95, 350, UIScreen.main.bounds.height - 70]))
        .impact(.light)
    }
}

struct DrawerView: View {
    @ObservedObject var sharedList: SharedList
    @State var search: String = ""
    var body: some View {
        SearchView(sharedList: sharedList)
        Divider()
        //        ScrollView {
        LocationList(sharedList: sharedList)
        //        }
    }
}

struct SearchView: View {
    @ObservedObject var sharedList: SharedList
    @State private var searchString: String = ""
    @FocusState private var searchFocus: Bool
    @State private var showDocumentPicker = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField(
                    //                "\(Image(systemName: "magnifyingglass"))Search",
                    "Search",
                    text: $searchString
                )
                .onSubmit {
                    print("submitted")
                }
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                //               .background(.gray.opacity(0.1))
                //               .cornerRadius(10)
                //               .foregroundColor(.primary)
                //               .font(.system(size: 18))
                .focused($searchFocus)
                .overlay(alignment: .trailing) {
                    if searchFocus {
                        // TODO: Drawer shoud go to highest position
                        // TODO: Setting buttons repalced with cancel
                        // TODO: If drawer minimized there should be a loss of focus
                        // TODO: x should appear when there is text
                        // TODO: replace view with search view
                        if (!searchString.isEmpty) {
                            Button( action:{
                                searchString = ""
                            }, label: {Image(systemName:"xmark.circle.fill")})
                            .offset(x: -5)
                            .foregroundStyle(Color(UIColor.systemGray2))
                        }
                    }
                }
                .background(.gray.opacity(0.1))
            }
            Button(action: {
                print("settings")
                showDocumentPicker = true
            }, label: {
                Image(systemName: "gearshape.2.fill")
                    .foregroundStyle(Color(uiColor: .systemGray))
            })
            .sheet(isPresented: $showDocumentPicker, content: {
                DocumentPicker(sharedList: sharedList)
            })
        }
        .padding([.top, .top], 7)
        .padding([.leading, .trailing], 10)
        // TODO: Make a search bar, search map using MapKit and your Location combined
        // TODO: Settings button should do some google drive stuff IDK in a sheet
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @ObservedObject var sharedList: SharedList
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.text], asCopy: true)
        documentPicker.delegate = context.coordinator
        return documentPicker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update needed
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        func documentPicker(_ controller:
                            UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let fileURL = urls.first else { return
            }
            parent.sharedList.changeLocationFile(newURL: fileURL)
        }
    }
}


struct LocationList: View {
    @ObservedObject var sharedList: SharedList
    var body: some View {
        let folderList: [LocationLayer] = sharedList.layerList
        // TODO: List layers and locations, make locations clickable, layers hideable
        ScrollView {
            VStack {
                ForEach(folderList, content: { list in
                    Layer(nameOfLayer: list.name, listOfLocations: list.locations)
                })
            }
        }
    }
}

struct Layer: View {
    @State var nameOfLayer: String
    @State var listOfLocations: [Location]
    @State private var showLayer: Bool = true
    var body: some View {
        //            HStack {
        //                Toggle(isOn: $showLayer, label: {
        //                    Text("Show layer")
        //                })
        //                .labelsHidden()
        //                .scaleEffect(0.8)
        //                .position(x: 50, y: 20)
        //                Text("\(nameOfLayer)")
        //                 ScrollView {
        //                     VStack {
        ForEach(listOfLocations, content: { location in
            LocationButton(location: location)
        })
        //                     }
        //                }
        //                .position(x: 0, y: 20)
    }
    //            .border(Color(UIColor.systemGray3))
    //        }
}

struct LocationButton: View {
    @State var location: Location
    var body: some View {
        Button(action: {print(location.name)}, label: {
            //            HStack {
            //                Image("icon-1.png")
            //                    .scaleEffect(0.5)
            //                VStack {
            Text(location.name)
            
            //                }
            //            }
        })
    }
}

struct LocationView: View {
    var body: some View {
        // TODO: Show name, desc, cords, weather etc
        // TODO: Button that opens in maps or google maps for routing
        // TODO: Map should be showing location
        Text("Hello")
    }
}
