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

    @IBOutlet weak var sleepImageView: UIImageView!
    @IBOutlet weak var eatImageView: UIImageView!
    @IBOutlet weak var mapImageView: UIImageView!

    @IBOutlet weak var appsTableView: UITableView!

    var location: PlaceLocation? {
        didSet {
            if let location = location {
                if let image = location.infoImages?.first {
                    if let stringUrl = image.link.absoluteString {
                        if let url = NSURL(string: stringUrl + "?blur=20") {
                            imageView.sd_setImageWithURL(url)
                        }
                    }
                }
                appsTableView.reloadData()
            }
        }
    }

    var coordinate: CLLocationCoordinate2D? {
        didSet {
            if let coordinate = coordinate {
            PlacesApi.placesAroundLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), radius: 0, completionHandler: { [weak self] places, error in
                if let location = places?.first?.locations.first {
                    self?.location = location
                }
            }, types: [PlaceType.City], name: nil)
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

