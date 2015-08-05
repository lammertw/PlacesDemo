//
//  ViewController.swift
//  PlacesDemo
//
//  Created by Lammert Westerhoff on 28/07/15.
//  Copyright (c) 2015 NS. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!

    @IBOutlet weak var sleepImageView: UIImageView!
    @IBOutlet weak var eatImageView: UIImageView!
    @IBOutlet weak var mapImageView: UIImageView!

    @IBOutlet weak var appsTableView: UITableView!

    private let classifications = [
        "CLEAR_NIGHT": "Clear sky",
        "SNOW": "Snow",
        "CLEAR_DAY": "Clear sky",
        "PARTLY_CLOUDY_DAY": "Partly cloudy",
        "PARTLY_CLOUDY_NIGHT": "Partly cloudy",
        "RAIN": "Rain",
        "SLEET": "Sleet",
        "MIST": "Mist",
        "WIND": "Wind",
        "UNKNOWN": "Unknown"
    ]

    var location: PlaceLocation? {
        didSet {
            if let location = location {
                titleLabel.text = location.name ?? "Some place"
                if let image = location.infoImages?.first {
                    if let stringUrl = image.link.absoluteString {
                        if let url = NSURL(string: stringUrl + "?blur=15") {
                            imageView.sd_setImageWithURL(url)
                        }
                    }
                }
                appsTableView.reloadData()
            }
        }
    }

    private let temperatureFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var coordinate: CLLocationCoordinate2D? {
        didSet {
            if let coordinate = coordinate {
                PlacesApi.placesAroundLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), radius: 0, completionHandler: { [weak self] places, error in
                    if let location = places?.first?.locations.first {
                        self?.location = location
                    }
                }, types: [PlaceType.City], name: nil)
                Manager.sharedInstance.request(.GET, "http://ns-common-api.elasticbeanstalk.com/api/v1/weather/\(coordinate.latitude),\(coordinate.longitude)", parameters: nil, encoding: .JSON).responseJSON { [weak self] _, _, result, error in
                    println(result)
                    if let weather = ((result as? [String: AnyObject])?["payload"] as? [String: AnyObject])?["currently"] as? [String: AnyObject], let this = self {
                        if let classification = this.classifications[weather["classification"] as? String ?? "UNKNOWN"], temperature = weather["temp"] as? Double {
                            let name = this.location?.name ?? "Some place"
                            this.weatherLabel.text = "\(this.temperatureFormatter.stringFromNumber(temperature)!)°C - \(classification) in \(name)"
                        }
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.translucent = true
        navigationController?.view.backgroundColor = UIColor.clearColor()
        navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]

        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .ShortStyle
        dateLabel.text = formatter.stringFromDate(NSDate())

        sleepImageView.tintColor = UIColor.whiteColor()
        eatImageView.tintColor = UIColor.whiteColor()
        mapImageView.tintColor = UIColor.whiteColor()
    }

    override func viewDidAppear(animated: Bool) {
        if coordinate == nil {
            performSegueWithIdentifier("Map", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let dest = (segue.destinationViewController as? UINavigationController)?.viewControllers.first as? MapViewController {
            dest.doneAction = { [weak self] coordinate in
                self?.coordinate = coordinate
            }
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return location?.apps.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AppCell", forIndexPath: indexPath) as! AppCell
        cell.nameLabel.text = location?.apps[indexPath.row]["name"] as? String
        if let iconString = location?.apps[indexPath.row]["listLogoImage"]?["uri"] as? String {
            if let iconUrl = NSURL(string: iconString) {
                cell.iconImageView.sd_setImageWithURL(iconUrl)
            }
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let app = location?.apps[indexPath.row]["links"] as? [String: AnyObject] {
            // TODO try open app or web
        }
    }
}

class AppCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
}

@IBDesignable
class CircleView: UIView {

    func drawCanvas1(#frame: CGRect) {

        //// Oval Drawing
        var ovalPath = UIBezierPath(ovalInRect: CGRectMake(frame.minX + 1, frame.minY + 1, frame.width - 2, frame.height - 2))
        UIColor.whiteColor().setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
    }

    override func drawRect(rect: CGRect) {
        drawCanvas1(frame: rect)
    }
}

