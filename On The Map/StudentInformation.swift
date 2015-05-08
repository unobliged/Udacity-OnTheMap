//
//  StudentInformation.swift
//  On The Map
//
//  Created by Brian Ortega on 4/7/15.
//  Copyright (c) 2015 Brian Ortega. All rights reserved.
//

import Foundation

struct StudentInformation {
    var mapString: String = ""
    var mediaURL: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    
    init(dictionary: [String : AnyObject]) {
        if let ms = dictionary["mapString"] as? String, mu = dictionary["mediaURL"] as? String, fn = dictionary["firstName"] as? String, ln = dictionary["lastName"] as? String, lat = dictionary["latitude"] as? Double, long = dictionary["longitude"] as? Double {
            mapString = ms
            mediaURL = mu
            firstName = fn
            lastName = ln
            latitude = lat
            longitude = long
        }
    }
    
    static func arrayFromResults(results: [[String : AnyObject]]) -> [StudentInformation] {
        var studentArray = [StudentInformation]()
        
        for result in results {
            studentArray.append(StudentInformation(dictionary: result))
        }
        
        return studentArray
    }
}