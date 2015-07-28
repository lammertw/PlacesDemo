//
//  MapViewController.swift
//  PlacesDemo
//
//  Created by Lammert Westerhoff on 28/07/15.
//  Copyright (c) 2015 NS. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    var annotation: Annotation?

    var doneAction: ((CLLocationCoordinate2D) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func dismiss(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func done(sender: AnyObject) {
        if let annotation = annotation {
            doneAction?(annotation.coordinate)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func tap(sender: AnyObject) {
        let point = sender.locationInView(mapView)
        let coorindate = mapView.convertPoint(point, toCoordinateFromView: mapView)

        if annotation == nil {
            annotation = Annotation(coordinate: coorindate)
            mapView.addAnnotation(annotation!)
        } else {
            annotation!.coordinate = coorindate
        }



    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let annotationView: MKAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        annotationView.annotation = annotation
        annotationView.draggable = true
        return annotationView
    }
}

class Annotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
