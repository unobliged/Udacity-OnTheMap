//
//  PostingViewController.swift
//  On The Map
//
//  Created by Brian Ortega on 5/2/15.
//  Copyright (c) 2015 Brian Ortega. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class PostingViewController: UIViewController, UITextViewDelegate, MKMapViewDelegate {

    @IBOutlet weak var topTextView: UITextView!
    @IBOutlet weak var midTextView: UITextView!
    @IBOutlet weak var findButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    
    var mkpm : MKPlacemark!
    
    var buttonToggle = true // Using single button for finding on map and submitting link
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topTextView.delegate = self
        midTextView.delegate = self
        findButton.layer.cornerRadius = 10
        
        // Ensures button is positioned above map and still clickable
        findButton.layer.zPosition = 1
        self.mapView.userInteractionEnabled = false
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.text = "";
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @IBAction func findOnMap(sender: AnyObject) {
        if buttonToggle {
            // Signals to user that geocoding activity is taking place
            var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            self.view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            self.view.alpha = 0.5
            
            CLGeocoder().geocodeAddressString(midTextView.text, completionHandler: { (placemarks, error) in
                
                // Signals geocoding activity has ceased
                activityIndicator.stopAnimating()
                self.view.alpha = 1
                
                if error != nil {
                    var alert = UIAlertController(title: "Geolocation Error", message: "Could not geocode location, please enter valid location", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                self.buttonToggle = false
                self.topTextView.text = "[ADD A URL]"
                self.topTextView.editable = true
                self.topTextView.backgroundColor = UIColor.blueColor()
                self.topTextView.textColor = UIColor.whiteColor()
                
                self.midTextView.hidden = true
                self.findButton.setTitle("Submit", forState: UIControlState.Normal)
                
                // Geocoding returns an array; we will only consider first result
                let pm = placemarks as! [CLPlacemark]
                if pm.count > 0 {
                    self.mapView.hidden = false
                    self.mkpm = MKPlacemark(placemark: pm[0] as CLPlacemark)
                    self.mapView.addAnnotation(self.mkpm)
                    
                    // Zooms in map to appropriate region for placemark coordinates
                    let region = MKCoordinateRegion(center: self.mkpm.location.coordinate, span: MKCoordinateSpanMake(1, 1))
                    self.mapView.region = region
                }
            })
        } else {
            self.validateURL()
        }
    }
    
    func postStudentInformation(#url: NSString, location: MKPlacemark) {
        UdacityClient.sharedInstance().postStudentInformation(url: url, location: location) { (response) in
            if let status: AnyObject = response["status"], statusError: AnyObject = response["statusError"] {
                var alert = UIAlertController(title: "POST Response", message: "status: \(status), statusError: \(statusError)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                let statusCheck = status as! NSString
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    if statusCheck == "Successfully posted data" {
                        self.performSegueWithIdentifier("FinishedPostingSegue", sender: self)
                    } else {
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func validateURL() {
        // Using code from this SO post for regex validation on URL:
        // http://stackoverflow.com/questions/1471201/how-to-validate-an-url-on-the-iphone/24207852#24207852
        
        if let url = topTextView.text {
            let urlRegEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
            let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[urlRegEx])
            var urlTest = NSPredicate.predicateWithSubstitutionVariables(predicate)
            if predicate.evaluateWithObject(url) {
                self.postStudentInformation(url: topTextView.text, location: self.mkpm)
            } else {
                self.invalidURLAlert()
            }
        } else {
            self.invalidURLAlert()
        }
    }
    
    func invalidURLAlert() {
        var alert = UIAlertController(title: "Invalid URL", message: "Please enter a valid URL (begin with http:// or https://)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
