//
//  MapViewController.swift
//  On The Map
//
//  Created by Brian Ortega on 4/21/15.
//  Copyright (c) 2015 Brian Ortega. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var studentModel = StudentData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadMapAnnotations()
    }
    
    func loadMapAnnotations() {
        let ltbc = self.tabBarController as! LocationTabBarController
        self.studentModel = ltbc.studentModel
        let locations = self.studentModel.studentArray
        if locations.count == 0 { // Handles reload when coming back from posting view
            ltbc.refreshLocations() { (response) in
                let locations = self.studentModel.studentArray
                self.addAnnotations(locations)
            }
        } else {
            self.addAnnotations(locations)
        }
    }
    
    func addAnnotations(locations: [StudentInformation]) {
        var annotations = [MKPointAnnotation]()
        
        for location in locations {
            let lat = CLLocationDegrees(location.latitude)
            let long = CLLocationDegrees(location.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            var annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "\(location.firstName) \(location.lastName)"
            annotation.subtitle = location.mediaURL
            
            annotations.append(annotation)
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.mapView.addAnnotations(annotations)
        }
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .Red
            pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // Enables clicking annotation to open browser to go to URL
    func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()
            app.openURL(NSURL(string: annotationView.annotation.subtitle!)!)
        }
    }
    
    @IBAction func refreshLocations(sender: AnyObject) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        let ltbc = self.tabBarController as! LocationTabBarController
        ltbc.refreshLocations() { (response) in
            if response {
                self.loadMapAnnotations()
            } else {
                var alert = UIAlertController(title: "Refresh Failed", message: "Please wait a few seconds and try refreshing again", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
 }
