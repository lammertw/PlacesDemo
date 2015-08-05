//
//  PlacesApi.swift
//  NSXtra
//
//  Created by Lammert Westerhoff on 31/10/14.
//  Copyright (c) 2014 NS Reizigers. All rights reserved.
//

import UIKit
import CoreLocation

//let placesUrl = "http://ns-places-api.elasticbeanstalk.com/api/v2/places"
let placesUrl = "http://nsplacesapinsi-env.elasticbeanstalk.com/api/v2/places"
//let placesUrl = "http://localhost:8080/api/v2/places"

class PlacesApi {
    
    class func places(query: String, completionHandler: ([Place]?, NSError?) -> Void, types: [PlaceType]) -> Request {
        var parameters: [String: AnyObject] = ["q": query]
        PlacesApi.addTypes(&parameters, types: types)
        println("Calling places API with URL \(placesUrl), parameters \(parameters)")
        return Manager.sharedInstance.request(.GET, placesUrl, parameters: parameters)
            .responseJSON(completionHandler: responseHandler(completionHandler))
    }

    class func placeLocations(query: String, completionHandler: ([PlaceLocation]?, NSError?) -> Void, types: PlaceType...) -> Request {
        return PlacesApi.places(query, completionHandler: {
            places, error in
            
            var locations : [PlaceLocation]?
            if let p = places {
                locations = p.map({ $0.locations }).flatten()
            }
            
            completionHandler(locations, error)
        }, types: types)
    }
    
    class func placesAroundLocation(location: CLLocation, radius: Int = 5000, completionHandler: ([Place]?, NSError?) -> Void, types: [PlaceType], name: String? = nil) -> Request {
        var parameters: [String: AnyObject] = [
            "lat": location.coordinate.latitude,
            "lng": location.coordinate.longitude,
            "radius": radius,
            "screen-density": "ios-\(UIScreen.mainScreen().scale)"
        ]
        PlacesApi.addTypes(&parameters, types: types)
        if let name = name {
            parameters["name"] = name
        }
        println("Calling places API with URL \(placesUrl), parameters \(parameters)")
        return Manager.sharedInstance.request(.GET, placesUrl, parameters: parameters)
            .responseJSON(completionHandler: responseHandler(completionHandler))
    }

    class func placesForStationCode(stationCode: String, completionHandler: ([Place]?, NSError?) -> Void, types: [PlaceType], name: String? = nil) -> Request {
        var parameters: [String: AnyObject] = [
            "station_code": stationCode,
            "screen-density": "ios-\(UIScreen.mainScreen().scale)"
        ]
        PlacesApi.addTypes(&parameters, types: types)
        if let name = name {
            parameters["name"] = name
        }
        println("Calling places API with URL \(placesUrl), parameters \(parameters)")
        return Manager.sharedInstance.request(.GET, placesUrl, parameters: parameters)
            .responseJSON(completionHandler: responseHandler(completionHandler))
    }
    
    class func placeLocationsAroundLocation(location: CLLocation, radius: Int = 5000, completionHandler: ([PlaceLocation]?, NSError?) -> Void, name: String? = nil, types: PlaceType...) -> Request {
        return PlacesApi.placesAroundLocation(location, radius: radius, completionHandler: {
            places, error in
            
            var locations : [PlaceLocation]?
            if let p = places {
                locations = p.map({ $0.locations }).flatten()
            }
            
            completionHandler(locations, error)
            }, types: types, name: name)
    }

    class func addTypes(inout parameters: [String: AnyObject], types: [PlaceType]) {
        if count(types) > 0 {
            parameters["type"] = types.map { $0.rawValue }
        }
    }

    class func responseHandler(completionHandler: ([Place]?, NSError?) -> Void)(request: NSURLRequest,response: NSHTTPURLResponse?, JSON: AnyObject?, error: NSError?) {
        if let JSON = JSON as? Dictionary<String, AnyObject> {
            if let payload = JSON["payload"] as? [Dictionary<String, AnyObject>] {
                var places = [Place]()
                for results in payload {
                    let place = Place(placesJSON: results)
                    places.append(place)
                }
                completionHandler(places, nil)
            } else {
                completionHandler(nil, NSError(domain: "PlacesApi", code: 1, userInfo: nil))
            }

        } else {
            completionHandler(nil, error)
        }
    }

    class func details(place: PlaceLocation, completionHandler: (PlaceLocation?, NSError?) -> Void) {
        if let uri = place.uri {
            Manager.sharedInstance.request(.GET, uri).responseJSON { (_, _, JSON, error) in
                if let JSON = JSON as? Dictionary<String, AnyObject> {
                    if let payload = JSON["payload"] as? Dictionary<String, AnyObject> {
                        place.setFromJson(payload)
                        completionHandler(place, nil)
                    } else {
                        completionHandler(nil, NSError(domain: "PlacesApi", code: 1, userInfo: nil))
                    }
                } else {
                    completionHandler(nil, error)
                }
            }
        } else {
            completionHandler(place, nil)
        }
    }

}

extension PlaceLocation {
    convenience init(placesJSON: Dictionary<String, AnyObject>, type: PlaceType) {
        self.init(placeType: type)
        setFromJson(placesJSON)
    }

    func setFromJson(placesJSON: Dictionary<String, AnyObject>) {
        name = placesJSON["name"] as? String
        number = placesJSON["houseNumber"] as? String
        zip = placesJSON["postalCode"] as? String
        street = placesJSON["street"] as? String
        city = placesJSON["city"] as? String
        locationDescription = placesJSON["description"] as? String

        if let infoUrl = placesJSON["infoUrl"] as? String {
            self.infoUrl = NSURL(string: infoUrl)
        }

        if let uri = (placesJSON["link"] as? Dictionary<String, AnyObject>)?["uri"] as? String {
            self.uri = NSURL(string: uri)
        }

        if let lat = placesJSON["lat"] as? Double {
            if let lng = placesJSON["lng"] as? Double {
                placeLocation = CLLocation(latitude: lat, longitude: lng)
            }
        }
        
        open = PlaceOpen.Unknown
        if let o = placesJSON["open"] as? String {
            if let po = PlaceOpen(rawValue: o) {
                open = po
            }
        }
        
        if let open = placesJSON["openingHours"] as? Array<Dictionary<String, AnyObject>> {
            openingHours = [OpeningHour]()
            for o in open {
                
                switch(o["dayOfWeek"], o["startTime"], o["endTime"]) {
                case(.Some(let dayofWeek), .Some(let startTime), .Some(let endTime)) where dayofWeek is Int && startTime is String && endTime is String:
                    openingHours?.append(OpeningHour(weekday: dayofWeek as! Int, startTime: startTime as! String, endTime: endTime as! String))
                default:
                    break
                }
            }
        }
        
        if let images = placesJSON["infoImages"] as? Array<Dictionary<String, AnyObject>> {
            infoImages = [ResourceImage]()
            for image in images {
                if let link = (image["link"] as? Dictionary<String, AnyObject>)?["uri"] as? String {
                    if let rl = NSURL(string: link) {
                        infoImages?.append(ResourceImage(link: rl, json: image))
                    }
                }
            }
        }


        
    }
}

extension ResourceImage {
    convenience init(link: NSURL, json: Dictionary<String, AnyObject>) {
        self.init(link: link)
        
        if let title = json["title"] as? String {
            self.title = title
        }
        
        if let subtitle = json["subtitle"] as? String {
            self.subtitle = subtitle
        }
        
        if let body = json["body"] as? String {
            
            if body.hasPrefix("<![CDATA[") && body.hasSuffix("]]>") {
                self.body = body.substringWithRange(Range<String.Index>(start: advance(body.startIndex, 9), end: advance(body.endIndex, -3)))
            } else {
                self.body = body
            }
        }
        
        if let buttonLink = json["buttonLink"] as? String {
            if let bl = NSURL(string: buttonLink) {
                self.buttonLink = bl
            }
        }
        
        if let buttonText = json["buttonText"] as? String {
            self.buttonText = buttonText
        }
        
    }
}

extension Place {
    convenience init(placesJSON: Dictionary<String, AnyObject>) {
        
        let name = placesJSON["name"] as? String ?? ""
        let primaryColor = placesJSON["primaryColor"] as? String
        let type = PlaceType(rawValue: placesJSON["type"] as? String ?? "") ?? PlaceType.StationFacility
        
        var locations = [PlaceLocation]()
        for location in placesJSON["locations"] as! [Dictionary<String, AnyObject>] {
            let placeLocation = PlaceLocation(placesJSON: location, type: type)
            placeLocation.apps = location["apps"] as! [[NSObject:AnyObject]]
            locations.append(placeLocation)
        }
        
        var listLogoImageURL: NSURL? = nil
        if let url = (placesJSON["listLogoImage"] as? Dictionary<String, AnyObject>)?["uri"] as? String {
            listLogoImageURL = NSURL(string: url)
        }
        
        var headerImageURL: NSURL? = nil
        if let url = (placesJSON["headerImage"] as? Dictionary<String, AnyObject>)?["uri"] as? String {
            headerImageURL = NSURL(string: url)
        }
        
        var advertImages: [ResourceImage]? = nil
        if let images = placesJSON["advertImages"] as? Array<Dictionary<String, AnyObject>> {
            advertImages = [ResourceImage]()
            for image in images {
                if let link = (image["link"] as? Dictionary<String, AnyObject>)?["uri"] as? String {
                    if let rl = NSURL(string: link) {
                        advertImages?.append(ResourceImage(link: rl, json: image))
                    }
                }
            }
        }
    
        var infoImages: [ResourceImage]? = nil
        if let images = placesJSON["infoImages"] as? Array<Dictionary<String, AnyObject>> {
            infoImages = [ResourceImage]()
            for image in images {
                if let link = (image["link"] as? Dictionary<String, AnyObject>)?["uri"] as? String {
                    if let rl = NSURL(string: link) {
                            infoImages?.append(ResourceImage(link: rl, json: image))
                    }
                }
            }
        }

        let open = PlaceOpen(rawValue: placesJSON["open"] as? String ?? "") ?? PlaceOpen.Unknown
        
        var openingHours: [OpeningHour]?
        if let open = placesJSON["openingHours"] as? Array<Dictionary<String, AnyObject>> {
            openingHours = [OpeningHour]()
            for o in open {
                
                switch(o["dayOfWeek"], o["startTime"], o["endTime"]) {
                case(.Some(let dayofWeek), .Some(let startTime), .Some(let endTime)) where dayofWeek is Int && startTime is String && endTime is String:
                    openingHours?.append(OpeningHour(weekday: dayofWeek as! Int, startTime: startTime as! String, endTime: endTime as! String))
                default:
                    break
                }
            }
        }
        
        let categories: [String]? = placesJSON["categories"] as? [String]

        let stationBound = placesJSON["stationBound"] as? Bool ?? false
        
        self.init(locations: locations, type: type, name: name, listLogoImageURL: listLogoImageURL, headerImageURL: headerImageURL, open: open, advertImages: advertImages, infoImages: infoImages, primaryColor: primaryColor, openingHours: openingHours, categories: categories, stationBound: stationBound)
    
    }
}


extension Array {

    func flatten<T>() -> [T] {
        let xs = (self as Any) as! [[T]]
        return xs.reduce([T]()) { (x, acc) in x + acc }
    }

    func any() -> T? {

        if self.count > 0 {
            let index = Int(arc4random_uniform(UInt32(self.count)))
            return self[index]
        } else {
            return nil
        }
    }

    func shuffled() -> [T] {
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }

    func hasAny(predicate: (T -> Bool)) -> Bool {
        return self.filter(predicate).count > 0
    }

    func hasNone(predicate: (T -> Bool)) -> Bool {
        return !hasAny(predicate)
    }
}
