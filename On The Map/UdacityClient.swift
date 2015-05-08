//
//  UdacityClient.swift
//  On The Map
//
//  Created by Brian Ortega on 4/2/15.
//  Copyright (c) 2015 Brian Ortega. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class UdacityClient {

    var session : NSURLSession
    var accountKey : String? = nil
    var sessionID : String? = nil
    var userFirstName : String? = nil
    var userLastName : String? = nil
    
    // Please add the appropriate appID and api key values locally before running
    var parseApplicationID: String = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    var parseAPIKey: String = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    
    init() {
        session = NSURLSession.sharedSession()
    }
    
    func loginWithUserCredentials(username: String, password: String, completionHandler: (response: NSDictionary) -> Void) -> NSURLSessionDataTask {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://www.udacity.com/api/session")!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"udacity\": {\"username\": \"\(username)\", \"password\": \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            if error != nil {
                println(error)
                completionHandler(response: ["status": "???", "statusError": "network error"])
                return
            }
            
            let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
            UdacityClient.parseJSONWithCompletionHandler(newData, completionHandler: { (data, error) in
                if error != nil {
                    println(error)
                    completionHandler(response: ["status": "???", "statusError": "error parsing response"])
                    return
                }
                
                UdacityClient.handleLoginResponse(data) { (response) in
                    completionHandler(response: response)
                }
            })
        }
        task.resume()
        
        return task
    }
    
    class func handleLoginResponse(parsedJSON: AnyObject, completionHandler: (response: NSDictionary) -> Void) {
        if let status: AnyObject = parsedJSON["status"], statusError: AnyObject = parsedJSON["error"] {
                let response = ["status": status, "statusError": statusError]
                completionHandler(response: response)
        } else if let account: AnyObject = parsedJSON["account"], session: AnyObject = parsedJSON["session"] {
            let key = account["key"] as! String
            let id = session["id"] as! String
            let response = ["accountKey": key, "sessionID": id]
            completionHandler(response: response)
        }
    }
    
    func getStudentLocations(completionHandler: (response: NSDictionary) -> Void) -> NSURLSessionDataTask {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://api.parse.com/1/classes/StudentLocation?limit=100")!) // As per requirements, limiting reques to 100 here
        request.addValue(parseApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(parseAPIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            if error != nil {
                println(error)
                completionHandler(response: ["status": "???", "statusError": "network error"])
                return
            }
            
            UdacityClient.parseJSONWithCompletionHandler(data, completionHandler: { (data, error) in
                if error != nil {
                    println(error)
                    completionHandler(response: ["status": "???", "statusError": "error parsing response"])
                    return
                }
                
                if let parseResponse = data as? NSDictionary {
                    completionHandler(response: parseResponse)
                }
            })
        }
        task.resume()
        
        return task
    }
    
    func getUserData(completionHandler: (response: Bool) -> Void) {
        if let userId = self.accountKey {
            let request = NSMutableURLRequest(URL: NSURL(string: "https://www.udacity.com/api/users/\(userId)")!)
            
            let task = session.dataTaskWithRequest(request) { data, response, error in
                if error != nil {
                    println(error)
                    completionHandler(response: false)
                    return
                }
                
                let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5))
                UdacityClient.parseJSONWithCompletionHandler(newData, completionHandler: { (data, error) in
                    if error != nil {
                        println(error)
                        completionHandler(response: false)
                        return
                    }
                    
                    if let user = data["user"] as? NSDictionary {
                        if let firstName = user["first_name"] as? String, lastName = user["last_name"] as? String {
                            self.userFirstName = firstName
                            self.userLastName = lastName
                            completionHandler(response: true)
                        } else {
                            completionHandler(response: false)
                        }
                    }
                })
            }
            task.resume()
        }
    }
    
    func postStudentInformation(#url: NSString, location: MKPlacemark, completionHandler: (response: NSDictionary) -> Void) {
        
        self.getUserData() { (response) in
            if response {
                let request = NSMutableURLRequest(URL: NSURL(string: "https://api.parse.com/1/classes/StudentLocation")!)
                request.HTTPMethod = "POST"
                request.addValue(self.parseApplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
                request.addValue(self.parseAPIKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let uniqueKey = self.accountKey, firstName = self.userFirstName, lastName = self.userLastName {
                    request.HTTPBody = "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"Mountain View, CA\", \"mediaURL\": \"\(url)\",\"latitude\": \(location.coordinate.latitude), \"longitude\": \(location.coordinate.longitude)}".dataUsingEncoding(NSUTF8StringEncoding)
                    
                    let task = self.session.dataTaskWithRequest(request) { (data, response, error) in
                        if error != nil {
                            println(error)
                            completionHandler(response: ["status": "???", "statusError": "network error"])
                            return
                        }
                        
                        UdacityClient.parseJSONWithCompletionHandler(data, completionHandler: { (data, error) in
                            if error != nil {
                                println(error)
                                completionHandler(response: ["status": "???", "statusError": "error parsing response"])
                                return
                            }
                            
                            UdacityClient.handlePOSTResponse(data) { (response) in
                                completionHandler(response: response)
                            }
                        })
                    }
                    task.resume()
                }
            } else {
                println("getUserData failed, no POST initiated")
            }
        }
    }
    
    class func handlePOSTResponse(parsedJSON: AnyObject, completionHandler: (response: NSDictionary) -> Void) {
        if let status: AnyObject = parsedJSON["status"], statusError: AnyObject = parsedJSON["error"] {
                let response = ["status": status, "statusError": statusError]
                completionHandler(response: response)
        } else if let createdAt: AnyObject = parsedJSON["createdAt"], objectId: AnyObject = parsedJSON["objectId"] {
                let response = ["status": "Successfully posted data", "statusError": "None"]
                completionHandler(response: response)
        } 
    }
        
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    class func sharedInstance() -> UdacityClient {
        struct Singleton {
            static var sharedInstance = UdacityClient()
        }
        
        return Singleton.sharedInstance
    }
}
