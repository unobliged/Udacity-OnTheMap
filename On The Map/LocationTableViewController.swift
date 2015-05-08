//
//  LocationTableViewController.swift
//  On The Map
//
//  Created by Brian Ortega on 4/27/15.
//  Copyright (c) 2015 Brian Ortega. All rights reserved.
//

import UIKit

class LocationTableViewController: UITableViewController, UITableViewDataSource {

    var studentModel = StudentData()
    var locations = [StudentInformation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadLocationData()
    }
    
    func loadLocationData() {
        let ltbc = self.tabBarController as! LocationTabBarController
        self.studentModel = ltbc.studentModel
        self.locations = self.studentModel.studentArray
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListViewCell") as! UITableViewCell
        let location = locations[indexPath.row]
        cell.imageView?.image = UIImage(named: "pin")
        cell.textLabel?.text = location.firstName + " " + location.lastName
        
        return cell
    }
    
    // Enables clicking row to open browser to go to URL
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let location = locations[indexPath.row]
        UIApplication.sharedApplication().openURL(NSURL(string: location.mediaURL)!)
    }
    
    @IBAction func refreshLocations(sender: AnyObject) {
        let ltbc = self.tabBarController as! LocationTabBarController
        ltbc.refreshLocations() { (response) in
            self.loadLocationData()
        }
    }
}
