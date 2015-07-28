//
//  Place.swift
//  NSXtra
//
//  Created by Lammert Westerhoff on 31/10/14.
//  Copyright (c) 2014 NS Reizigers. All rights reserved.
//
import MapKit
import Foundation

public enum PlaceType: String {
    case
        StationTaxi = "station-taxi",
        StationFacility = "stationfacility",
        StationRetail = "station-retail",
        OVFiets = "ovfiets",
        QPark = "qpark",
        Greenwheels = "greenwheels",
        Address = "address",
    Station = "station",
    City = "city"
}

public enum StationPlaceType {
    case Rich
    case Basic
    case Retail
}

public enum PlaceOpen: String {
    case Yes = "Yes", No = "No", Unknown = "Unknown"
}

func placeLocationsContainsLocationsWithLatLng(locations: [PlaceLocation]) -> Bool {
    return locations.filter({ $0.placeLocation != nil }).count > 0
}

public class Place: NSObject {
    
    public let locations: [PlaceLocation]
    public let type: PlaceType
    public let name: String
    public let listLogoImageURL: NSURL?
    public let headerImageURL: NSURL?
    public let open: PlaceOpen
    public let advertImages, infoImages: [ResourceImage]?
    public let openingHours: [OpeningHour]?
    public let categories: [String]?
    public let stationBound: Bool
    
    let primaryColor = UIColor.blackColor()
    
    lazy var detailsAvailable: Bool = {
        if self.stationPlaceType == .Rich {
            return true
        } else if self.isFacility() {
            return self.open != PlaceOpen.Unknown && self.containsLocationsWithLatLng
        } else {
            return self.open != PlaceOpen.Unknown || self.containsLocationsWithLatLng
        }
    }()
    
    lazy var containsLocationsWithLatLng: Bool = {
        return placeLocationsContainsLocationsWithLatLng(self.locations)
    }()
    
    public init(locations: [PlaceLocation], type: PlaceType, name: String, listLogoImageURL: NSURL?, headerImageURL: NSURL?, open: PlaceOpen, advertImages: [ResourceImage]?, infoImages: [ResourceImage]?, primaryColor: String?, openingHours: [OpeningHour]?, categories: [String]?, stationBound: Bool) {
        self.locations = locations
        self.type = type
        self.name = name
        self.listLogoImageURL = listLogoImageURL
        self.headerImageURL = headerImageURL
        self.open = open
        self.infoImages = infoImages
        self.advertImages = advertImages
        self.openingHours = openingHours
        self.categories = categories
        self.stationBound = stationBound
        
        
    }

    func hasCategory(category: String) -> Bool {
        return Place.hasCategory(category, inCategories: categories)
    }

    private class func hasCategory(category: String, inCategories categories: [String]?) -> Bool {
        if let categories = categories {
            return contains(categories, category)
        }
        return false
    }
    
    public func isRetail() -> Bool {
        return self.type == PlaceType.StationRetail && !hasCategory("Services")
    }

    public func isFacility() -> Bool {
        return Place.isFacility(type, categories: categories)
    }

    private class func isFacility(type: PlaceType, categories: [String]?) -> Bool {
        let facilities = [PlaceType.StationFacility, PlaceType.OVFiets, PlaceType.QPark, PlaceType.Greenwheels]
        return contains(facilities, type) || Place.hasCategory("Services", inCategories: categories)
    }

    public var stationPlaceType: StationPlaceType {
        get {
            if type != .StationRetail {
                if let categories = categories where contains(categories, "servicerich") {
                    return .Rich
                }
                return .Basic
            }
            return .Retail
        }
    }
}

public class OpeningHour {
    
    let currentWeekday: Int = {
        let w = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitWeekday, fromDate: NSDate()).weekday - 1
        if w == 0 { //change sunday to monday
            return 7
        } else {
            return w
        }
    }()

    let weekday: Int
    let startTime: String
    let endTime: String
    
    var isToday: Bool {
        return weekday == currentWeekday
    }
    
    var isTomorrow: Bool {
        let nextWeekday = (currentWeekday + 1 == 8) ? 1 : currentWeekday + 1
        return (weekday == nextWeekday)
    }
    
    init(weekday: Int, startTime: String, endTime: String) {
        self.weekday = weekday
        self.startTime = startTime
        self.endTime = endTime
    }
}

public class PlaceLocation: NSObject, Equatable {
    var city, name, number, street, zip: String?
    var placeLocation: CLLocation?
    var uri: NSURL?
    var locationDescription: String?
    var openingHours: [OpeningHour]?
    var open: PlaceOpen?
    var infoImages: [ResourceImage]?
    var placeType: PlaceType
    var infoUrl: NSURL?
    public var apps = [[NSObject:AnyObject]]()
    
    public init(placeType: PlaceType) {
        self.placeType = placeType
        super.init()
    }
    
}

public class ResourceImage: Equatable {
    
    let link: NSURL
    
    var title, subtitle, body, buttonText: String?
    var buttonLink: NSURL?
    
    public init(link: NSURL) {
        self.link = link
    }
    
}

public func ==(lhs: ResourceImage, rhs: ResourceImage) -> Bool {
    return lhs.link == rhs.link && lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
}


func sortPlacesByDistanceFromLocation(location: CLLocation)(t1: PlaceLocation, t2: PlaceLocation) -> Bool {
    return location.distanceFromLocation(t1.placeLocation) < location.distanceFromLocation(t2.placeLocation)
}

extension PlaceLocation: MKAnnotation {

    public var coordinate: CLLocationCoordinate2D {
        if let location = placeLocation {
            return location.coordinate
        } else {
            return CLLocationCoordinate2DMake(0, 0)
        }
    }

    public var title: String? {
        // stations have a name we want to use on the Annotations. Other places usually have a name too long, so if the name contains the street we create our own short version of it
        if name == nil || street == nil || name?.rangeOfString(street!) != nil {
            if let address = address {
                return address
            }
        }
        return name
    }

    func splitNameIntoAddressAndCity() -> [String]? {
        if let name = name {
            return name.componentsSeparatedByString(",").map({ $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) })
        } else {
            return nil
        }
    }

    var address: String? {
        if street != nil && number != nil {
            return "\(street!) \(number!)"
        }
        return splitNameIntoAddressAndCity()?.first
    }

    var derivedCity: String? {
        if let city = city {
            return city
        }
        return splitNameIntoAddressAndCity()?.last
    }
}

public func ==(lhs: PlaceLocation, rhs: PlaceLocation) -> Bool {
    return lhs.isEqual(rhs)
}

extension UIColor {
    convenience init(rgba: String) {
        
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if rgba.hasPrefix("#") {
            let index   = advance(rgba.startIndex, 1)
            let hex     = rgba.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                if count(hex) == 6 {
                    red   = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)  / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF) / 255.0
                } else if count(hex) == 8 {
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                } else {
                    print("invalid rgb string, length should be 7 or 9")
                }
            } else {
                println("scan hex error")
            }
        } else {
            print("invalid rgb string, missing '#' as prefix")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}

extension UIImageView {

    func setPlace(place: Place?, completed: (() -> ())? = nil ) {
        if place?.type == PlaceType.StationRetail {
            image = UIImage(named: "shopEmpty.jpg")
        } else if place?.type == PlaceType.StationFacility {
            image = UIImage(named: "servicesEmptyLogo")
        } else {
            image = nil
        }

        if let imageURL = place?.listLogoImageURL {
            sd_setImageWithURL(imageURL, placeholderImage: image, completed: { _, _, _, _ in
                completed?()
            })
        }
    }
}

