//
//  KMLParser.swift
//  My Map
//
//  Created by Anthony on 7/27/24.
//

import Foundation
import SwiftData

// TODO: restructure and make more efficient


struct DataContainer: Encodable {
    let LocationLayers: [LocationLayer]?
    let iconMap: [String: String]?
}

// TODO: background thread??
class SharedList: ObservableObject {
    @Published var locationFile: URL?
    @Published var layerList: [LocationLayer]
    var iconMap: Dictionary<String, String>
    var jsonUrl: URL
    
    init() {
        //        locationFile = URL(fileURLWithPath: "resources/doc.kml")
        locationFile = Bundle.main.url(
            forResource: "doc",
            withExtension: "kml"
        )
        layerList = []
        iconMap = [:]
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        jsonUrl = url.appendingPathComponent("LocationntsList.json")
        if locationFile != nil {
            readJSON()
        }
    }
    
    private func readFile(path: String) throws -> String {
        let fileURL = URL(fileURLWithPath: path)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return content
    }
    
    func changeLocationFile(newURL: URL) {
        locationFile = newURL
        writeJSON()
    }
    
    func writeJSON() {
        if let _ = locationFile {
//            print(locationFile!)
            parseKML()
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted] // Optional formatting
                let jsonData = try encoder.encode(layerList)
                try jsonData.write(to: jsonUrl, options: .atomic)
            } catch {
                // FIXME: add things here
            }
        }
    }
    
    func readJSON() {
        // TODO: read json, make array of layers
        do {
            let data = try Data(contentsOf: jsonUrl)
            let decoder = JSONDecoder()
            layerList = try decoder.decode([LocationLayer].self, from: data)
        } catch {
            print("could not decode json")
        }
    }
    
    func parseKML() {
        if let unwrappedFile = locationFile {
            parseKMLHelp(unwrappedFile: unwrappedFile)
        } else {
            // TODO: handle file is nil
        }
    }
    
    func parseKMLHelp(unwrappedFile: URL) {
        let parser: XMLParser
        if let stream = InputStream(url: unwrappedFile) {
            parser = XMLParser(stream: stream)
        } else {
            return
        }
        iconMap = Dictionary()
        let parserDelagate = ParserDelegate()
        parser.delegate = parserDelagate
        parser.parse()
        iconMap = parserDelagate.getDict()
        layerList = parserDelagate.getLayerList()
        //        iconMap.reverse()
        //        print(iconMap)
        //        print(layerList)
    }
}

class ParserDelegate: NSObject, XMLParserDelegate {
    var iconMap: Dictionary<String, String>
    var layerList: [LocationLayer]
    var currentElement: String = ""
    var currentIcon: String = ""
    var currentLocationLayerList: LocationLayer = LocationLayer()
    var currentLocation: Location = Location()
    var inPlacemark: Bool = false
    var inStyle: Bool = false
    
    override init () {
        self.iconMap = [:]
        self.layerList = [LocationLayer]()
    }
    
    //    let iconIDReg = /icon-[A-Za-z0-9]*-[A-Za-z0-9]*-nodesc(?!.)/
    let iconIDReg = /icon-[A-Za-z0-9]*-[A-Za-z0-9]*-nodesc-normal/
    
    func getDict() -> Dictionary<String, String> {
        return iconMap
    }
    
    func getLayerList() -> [LocationLayer] {
        return layerList
    }
    
    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        if (string.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
            switch currentElement {
            case "href":
                if iconMap[currentIcon] == "" {
                    let newString = string.trimmingCharacters(in: .whitespacesAndNewlines).trimmingPrefix("images/")
                    iconMap[currentIcon] = String(newString)
                }
            case "name":
                if inPlacemark {
                    currentLocation.name = string.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    currentLocationLayerList.name = string.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            case "description":
                currentLocation.desc = string.trimmingCharacters(in: .whitespacesAndNewlines)
            case "styleUrl":
                if inPlacemark {
                    let searchString = String(string.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "-nodesc")[0].trimmingPrefix("#"))
                    currentLocation.icon = iconMap[searchString] ?? ""
                }
            case "coordinates":
                let coords = string.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
                currentLocation.lati = Double(coords[0]).unsafelyUnwrapped
                currentLocation.long = Double(coords[1]).unsafelyUnwrapped
            default:
                _ = 1
            }
        }
    }
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        for (_, attr_val) in attributeDict {
            if let _ = try? iconIDReg.wholeMatch(in: attr_val) {
                currentIcon = String(attr_val.split(separator: "-nodesc-normal")[0])
                iconMap[currentIcon] = ""
                //                iconMap[String(currentIcon.split(separator: "-nodesc")[0])] = ""
                
                
            }
        }
//        print("start: " + elementName)
        switch elementName {
        case "Placemark":
            inPlacemark = true
        case "Folder":
            inPlacemark = false
        default:
            _ = 0
        }
        currentElement = elementName
    }
    
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "Placemark":
            inPlacemark = true
//            currentLocation.setCoords()
//            print(currentLocation.coordinate)
            currentLocationLayerList.locations.append(currentLocation)
            currentLocation = Location()
        case "Folder":
            inPlacemark = false
            layerList.append(currentLocationLayerList)
            currentLocationLayerList = LocationLayer()
        default:
            _ = 0
        }
    }
}

/*
 The protocol method foundCharacters is fired between the start and the end of an element. Maybe several times. You have to implement that method and append the characters found to a string variable, depending on the name of the element.
 
 When didEndElement is fired, your string variable is filled completely with the content of the element
 */

/*
 struct Location: Identifiable {
 var name: String
 var desc: String
 var layer: String
 var lati: Double
 var long: Double
 var icon: String
 }
 */

/*
 Need: style - id and icon href
 */

/*
 <description/>
 <Style id="icon-1528-795548-nodesc-normal">
 <IconStyle>
 <scale>1</scale>
 <Icon>
 <href>images/icon-4.png</href>
 </Icon>
 </IconStyle>
 <LabelStyle>
 <scale>0</scale>
 </LabelStyle>
 <BalloonStyle>
 <text><![CDATA[<h3>$[name]</h3>]]></text>
 </BalloonStyle>
 </Style>
 <Style id="icon-1528-795548-nodesc-highlight">
 <IconStyle>
 <scale>1</scale>
 <Icon>
 <href>images/icon-4.png</href>
 </Icon>
 </IconStyle>
 <LabelStyle>
 <scale>1</scale>
 </LabelStyle>
 <BalloonStyle>
 <text><![CDATA[<h3>$[name]</h3>]]></text>
 </BalloonStyle>
 </Style>
 <StyleMap id="icon-1528-795548-nodesc">
 <Pair>
 <key>normal</key>
 <styleUrl>#icon-1528-795548-nodesc-normal</styleUrl>
 </Pair>
 <Pair>
 <key>highlight</key>
 <styleUrl>#icon-1528-795548-nodesc-highlight</styleUrl>
 </Pair>
 </StyleMap>
 <Style id="icon-1573-0097A7-normal">
 <IconStyle>
 <scale>1</scale>
 <Icon>
 <href>images/icon-6.png</href>
 </Icon>
 </IconStyle>
 <LabelStyle>
 <scale>0</scale>
 </LabelStyle>
 </Style>
 
 */


/*
 <Folder>
 <name>Stores</name>
 <Placemark>
 <name><![CDATA[John's Sporting Goods]]></name>
 <styleUrl>#icon-1686-A52714-nodesc</styleUrl>
 <Locationnt>
 <coordinates>
 -122.2008239,47.9918257,0
 </coordinates>
 </Locationnt>
 </Placemark>
 <Placemark>
 <name><![CDATA[Triangle Bait & Tackle]]></name>
 <styleUrl>#icon-1686-A52714-nodesc</styleUrl>
 <Locationnt>
 <coordinates>
 -122.0891923,47.9126187,0
 </coordinates>
 </Locationnt>
 </Placemark>
 */
