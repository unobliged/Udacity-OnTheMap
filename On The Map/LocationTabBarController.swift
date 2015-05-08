//
//  LocationTabBarController.swift
//  On The Map
//
//  Created by Brian Ortega on 4/21/15.
//  Copyright (c) 2015 Brian Ortega. All rights reserved.
//

import UIKit

class LocationTabBarController: UITabBarController {

    var studentModel = StudentData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Shared function for map and table views to refresh locations
    func refreshLocations(completionHandler: (response: Bool) -> Void) {
        UdacityClient.sharedInstance().getStudentLocations() { (response) in
            if let results = response["results"] as? [[String : AnyObject]] {
                self.studentModel.studentArray = StudentInformation.arrayFromResults(results)
                completionHandler(response: true)
            } else {
                self.checkForError(response)
                completionHandler(response: false)
            }
        }
    }
    
    func checkForError(response: NSDictionary) {
        if let status: AnyObject = response["status"], statusError: AnyObject = response["statusError"] {
            var alert = UIAlertController(title: "Data Error", message: "status: \(status), statusError: \(statusError)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
}
