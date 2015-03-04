//
//  LoginController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-08.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginFacebookController: UIViewController, UINavigationControllerDelegate {

    @IBAction func cancelButtonPressed(sender: UITabBarItem) {
        dismissLoginModalController()
    }

    @IBOutlet var buttons: [UIButton]!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    /// Label with connection related errors
    @IBOutlet weak var connectionErrorMessage: UILabel!
    /// Label with Facebook/server related errors
    @IBOutlet weak var facebookErrorMessage: UILabel!
    @IBAction func loginWithFacebookButtonPressed(sender: UIButton) {

        // Set loading interface
        for button in buttons {
            button.enabled = false
        }
        navigationItem.leftBarButtonItem?.enabled = false
        activityIndicator.startAnimating()
        // Hide error messages
        connectionErrorMessage.hidden = true
        facebookErrorMessage.hidden = true

        // Clean login caches
        ParseUser.logOut()

        // Login
        PFFacebookUtils.logInWithPermissions(["public_profile", "user_friends", "email"]) { (user, error) -> Void in

            if let unwrappedUser = user as? ParseUser {

                // Successful login
                NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)

                // If user is not new, finish login flow. Otherwise, download information from Facebook and go to next screen.
                if unwrappedUser.facebookId != nil && countElements(unwrappedUser.facebookId!) > 0 && unwrappedUser.hasPassword == true {

                    // Go back to primary controller
                    self.dismissLoginModalController()

                } else {

                    // Get information from Facebook
                    FBRequestConnection.startWithGraphPath("me?fields=id,first_name,email,gender") { (requestConnection, result, error) -> Void in
                        // Send Facebook information for review in next screen
                        self.performSegueWithIdentifier("Sign Up", sender: result)
                    }
                }
                
            } else {

                // Unsuccessful login
                // Restore interface to default
                for button in self.buttons {
                    button.enabled = true
                }
                self.navigationItem.leftBarButtonItem?.enabled = true
                self.activityIndicator.stopAnimating()
                // Show error
                if let unwrappedFacebookErrorLoginFailedReason = error.userInfo?[FBErrorLoginFailedReason] as? String {
                    self.facebookErrorMessage.hidden = false
                } else {
                    self.connectionErrorMessage.hidden = false
                }
            }
        }
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let unwrappedId = segue.identifier {
            switch unwrappedId {

            case "Sign Up":
                if let facebookUser = sender as? FBGraphObject {
                    (segue.destinationViewController as LoginSignupController).facebookUser = facebookUser
                    segue.destinationViewController.navigationItem.hidesBackButton = true
                }
            default:
                return
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.delegate = self

        activityIndicator.stopAnimating()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Login: Main", block: nil)
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
}
