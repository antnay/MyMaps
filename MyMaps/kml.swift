//
//  KMLParser.swift
//  My Map
//
//  Created by Anthony on 7/27/24.
//

import Foundation

// TODO: Clean up this file please

struct POILayer: Identifiable, Encodable, Decodable {
    init(name: String, locations: [POI]) {
        self.name = name
        self.locations = locations
    }
    
    init() {
        name = ""
        locations = [POI]()
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
    var locations: [POI]
}

struct POI: Identifiable, Encodable, Decodable {
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
    
    let id: UUID = UUID()
    var name: String
    var desc: String
    var layer: String
    var lati: Double
    var long: Double
    var icon: String
}

struct DataContainer: Encodable {
    let poiLayers: [POILayer]
    let iconMap: [String: String]
}

func tempHardCodedList() -> [POILayer] {
    var returnList: [POILayer] = []
    var POILayer1: [POI] = []
    POILayer1.append(POI(name: "Sportco", desc: "", layer: "Stores", lati: 122.3663711, long: 47.2382278, icon: "icon-1.png"))
    POILayer1.append(POI(name: "Outdoor Emporium", desc: "Store in Seattle", layer: "Stores", lati: -122.3295316, long: 47.5878028, icon: "icon-1.png"))
    returnList.append(POILayer(name: "Stores", locations: POILayer1))
    var POILayer2: [POI] = []
    POILayer2.append(POI(name: "South Fork Snoqualmie River", desc: "Some river i guess", layer: "Rivers", lati: -121.630279, long: 47.4323793, icon: "icon-2.png"))
    returnList.append(POILayer(name: "Rivers", locations: POILayer2))
    var POILayer3: [POI] = []
    POILayer3.append(POI(name: "Pine Lake", desc: "", layer: "Lakes", lati: -122.041209, long: 47.5879223, icon: "icon-3.png"))
    returnList.append(POILayer(name: "Lakes", locations: POILayer3))
    return returnList
}

// TODO: background thread??
class SharedList: ObservableObject {
    @Published var locationFile: URL?
    @Published var layerList: [POILayer]
    var iconMap: Dictionary<String, String>
    var jsonUrl: URL
    
    init() {
        locationFile = URL(fileURLWithPath: "resources/doc.kml")
        layerList = []
        iconMap = [:]
        var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        jsonUrl = url.appendingPathComponent("pointsList.json")
        if locationFile != nil {
            readJSON()
        }
        
    }
    
    func changeLocationFile(newURL: URL) {
        locationFile = newURL
        writeJSON()
    }
    
    func writeJSON() {
        if let _ = locationFile {
            parseKML()
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted] // Optional formatting
                let jsonData = try encoder.encode(layerList)
                try jsonData.write(to: jsonUrl, options: .atomic)
            } catch {
                
            }
            }
        }
        
        func readJSON() {
            // TODO: read json, make array of layers
            do {
                let data = try Data(contentsOf: jsonUrl)
                let decoder = JSONDecoder()
                layerList = try decoder.decode([POILayer].self, from: data)
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
    var layerList: [POILayer]
    var currentElement: String = ""
    var currentIcon: String = ""
    var currentPOILayerList: POILayer = POILayer()
    var currentPOI: POI = POI()
    var inPlacemark: Bool = false
    var inStyle: Bool = false
    
    override init () {
        self.iconMap = [:]
        self.layerList = [POILayer]()
    }
    
//    let iconIDReg = /icon-[A-Za-z0-9]*-[A-Za-z0-9]*-nodesc(?!.)/
    let iconIDReg = /icon-[A-Za-z0-9]*-[A-Za-z0-9]*-nodesc-normal/
    
    func getDict() -> Dictionary<String, String> {
        return iconMap
    }
    
    func getLayerList() -> [POILayer] {
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
                     currentPOI.name = string.trimmingCharacters(in: .whitespacesAndNewlines)
                 } else {
                     currentPOILayerList.name = string.trimmingCharacters(in: .whitespacesAndNewlines)
                 }
             case "description":
                 currentPOI.desc = string.trimmingCharacters(in: .whitespacesAndNewlines)
             case "styleUrl":
                 if inPlacemark {
                     let searchString = String(string.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "-nodesc")[0].trimmingPrefix("#"))
                     currentPOI.icon = iconMap[searchString] ?? ""
                 }
             case "coordinates":
                 let coords = string.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
                 currentPOI.lati = Double(coords[0]).unsafelyUnwrapped
                 currentPOI.long = Double(coords[1]).unsafelyUnwrapped
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
//       print("end: " +  elementName)
         switch elementName {
         case "Placemark":
             inPlacemark = true
             currentPOILayerList.locations.append(currentPOI)
             currentPOI = POI()
         case "Folder":
             inPlacemark = false
             layerList.append(currentPOILayerList)
             currentPOILayerList = POILayer()
         default:
            _ = 0
         }
     }
}

extension Dictionary {
    
    func reverse() {
        self.forEach({ key, value in
            print(key)
            print(value)
        })
    }
}
        
        /*
 The protocol method foundCharacters is fired between the start and the end of an element. Maybe several times. You have to implement that method and append the characters found to a string variable, depending on the name of the element.
 
 When didEndElement is fired, your string variable is filled completely with the content of the element
 */

/*
 struct POI: Identifiable {
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
    <Point>
      <coordinates>
        -122.2008239,47.9918257,0
      </coordinates>
    </Point>
  </Placemark>
  <Placemark>
    <name><![CDATA[Triangle Bait & Tackle]]></name>
    <styleUrl>#icon-1686-A52714-nodesc</styleUrl>
    <Point>
      <coordinates>
        -122.0891923,47.9126187,0
      </coordinates>
    </Point>
  </Placemark>
*/
