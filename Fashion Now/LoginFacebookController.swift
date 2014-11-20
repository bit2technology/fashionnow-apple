//
//  LoginController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-08.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginFacebookController: UIViewController, UINavigationControllerDelegate {

    @IBAction func dismiss(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func loginButtonPressed(sender: UIButton) {
        PFFacebookUtils.logInWithPermissions(["public_profile", "user_friends", "email"]) { (user, error) -> Void in
            if let customUser = user as? User {
                FBRequestConnection.startForMeWithCompletionHandler() { (requestConnection, object, error) -> Void in
                    if let graphObject = object as? FBGraphObject {
                        println("user:\(graphObject)")
                        // Add Facebook information
                        customUser.name = graphObject.objectForKey("name") as? String
                        customUser.email = graphObject.objectForKey("email") as? String
                        customUser.gender = graphObject.objectForKey("gender") as? String
                        customUser.setBirthday(dateString: graphObject.objectForKey("birthday") as? String)
                        customUser.locationName = graphObject.objectForKey("location").objectForKey("name") as? String
                        customUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                }
            }
        }
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        var supportedOrientations = UIInterfaceOrientationMask.Portrait
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            supportedOrientations = .All
        }
        return Int(supportedOrientations.rawValue)
    }
}

extension UIViewController {
    
    func needsLogin() -> Bool {
        return false
    }
}

extension UINavigationController {

    override func needsLogin() -> Bool {
        return self.topViewController.needsLogin()
    }
}