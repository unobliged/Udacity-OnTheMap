//
//  InitialViewController.swift
//  On The Map
//
//  Created by Brian Ortega on 3/28/15.
//  Copyright (c) 2015 Brian Ortega. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController, UITextFieldDelegate {
    
    // Use for scaling/positioning buttons/textfields
    let screenSize: CGRect = UIScreen.mainScreen().bounds
    
    var appDelegate: AppDelegate!
    var session: NSURLSession!
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    
    var studentModel = StudentData() // This sets up the shared data model for the app
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        session = NSURLSession.sharedSession()
        self.setButtons()
    }
    
    func setButtons() {
        emailTextField = UITextField(frame: CGRectMake(screenSize.width * 0.05, screenSize.height * 0.4, screenSize.width * 0.9, screenSize.height * 0.075))
        emailTextField.attributedPlaceholder = NSAttributedString(string: "Email", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        emailTextField.backgroundColor = UIColor(red: 1, green: 0.75, blue: 0.5, alpha: 1)
        emailTextField.textColor = UIColor.whiteColor()
        emailTextField.clearsOnBeginEditing = true
        emailTextField.delegate = self
        self.view.addSubview(emailTextField)
        
        passwordTextField = UITextField(frame: CGRectMake(screenSize.width * 0.05, screenSize.height * 0.5, screenSize.width * 0.9, screenSize.height * 0.075))
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        passwordTextField.backgroundColor = UIColor(red: 1, green: 0.75, blue: 0.5, alpha: 1)
        passwordTextField.textColor = UIColor.whiteColor()
        passwordTextField.clearsOnBeginEditing = true
        passwordTextField.secureTextEntry = true
        passwordTextField.delegate = self
        self.view.addSubview(passwordTextField)
        
        let loginButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        loginButton.frame = CGRectMake(screenSize.width * 0.05, screenSize.height * 0.6, screenSize.width * 0.9, screenSize.height * 0.075)
        loginButton.setTitle("Login", forState: UIControlState.Normal)
        loginButton.backgroundColor = UIColor(red: 1, green: 0.35, blue: 0, alpha: 1)
        self.view.addSubview(loginButton)
        loginButton.addTarget(self, action: "loginButtonPress", forControlEvents: UIControlEvents.TouchUpInside)
        
        let signupButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        signupButton.frame = CGRectMake(screenSize.width * 0.05, screenSize.height * 0.7, screenSize.width * 0.9, screenSize.height * 0.075)
        signupButton.setTitle("Don't have an account? Sign Up", forState: UIControlState.Normal)
        self.view.addSubview(signupButton)
        signupButton.addTarget(self, action: "signupButtonPress", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func loginButtonPress() {
        UdacityClient.sharedInstance().loginWithUserCredentials(emailTextField.text, password: passwordTextField.text) { (response) in
            self.displayLoginResponse(response)
        }
    }
    
    func signupButtonPress() {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://www.udacity.com/account/auth#!/signup")!)
    }
    
    func displayLoginResponse(response: NSDictionary) {
        if let accountKey: AnyObject = response["accountKey"], sessionID: AnyObject = response["sessionID"] {
            UdacityClient.sharedInstance().accountKey = (accountKey as! String)
            UdacityClient.sharedInstance().getStudentLocations() { (response) in
                if let results = response["results"] as? [[String : AnyObject]] {
                    self.studentModel.studentArray = StudentInformation.arrayFromResults(results)
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.performSegueWithIdentifier("LocationViewSegue", sender: self)
                    }
                } else {
                    self.checkForError(response, type: "Parse API Error")
                }
            }
        } else {
            checkForError(response, type: "Login Error")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LocationViewSegue" {
            let ltbc = segue.destinationViewController as! LocationTabBarController
            ltbc.studentModel = studentModel // This passes the data model to the rest of the app
        }
    }
    
    func checkForError(response: NSDictionary, type: String) {
        if let status: AnyObject = response["status"], statusError: AnyObject = response["statusError"] {
            var alert = UIAlertController(title: type, message: "status: \(status), statusError: \(statusError)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
}
