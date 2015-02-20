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
        (self.presentingViewController as! TabBarController).willDismissLoginController()
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBOutlet var buttons: [UIButton]!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    /// Label with connection related errors
    @IBOutlet weak var connectionErrorMessage: UILabel!
    /// Label with Facebook/server related errors
    @IBOutlet weak var facebookErrorMessage: UILabel!
    @IBAction func loginWithFacebookButtonPressed(sender: UIButton) {
        loginWithFacebookButtonPressed(sender, retries: 1)
    }
    private func loginWithFacebookButtonPressed(sender: UIButton, retries: Int) {

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
        FBSession.activeSession().closeAndClearTokenInformation()

        // Login
        PFFacebookUtils.logInWithPermissions(["public_profile", "user_friends", "email"]) { (user, error) -> Void in
            NSLog("User: \(user) error: \(error)")

            if let customUser = user as? ParseUser {

                // Successful login
                NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)

                // Get user's Facebook information only if there is no error (if the user is new)
                if error == nil {
                    FBRequestConnection.startWithGraphPath("me?fields=id,first_name,email,gender") { (requestConnection, result, error) -> Void in
                        // Send Facebook information for review in next screen
                        self.performSegueWithIdentifier("Sign Up", sender: result)
                    }
                } else {
                    self.performSegueWithIdentifier("Sign Up", sender: nil)
                }

            } else {

                // Unsuccessful. The user might have disabled Fashion Now app in Facebook. In this case, the SDK needs to try to connect once, to clean token. That's why the app tries to connect to Facebook twice, unless user has explicitly rejected.
                if retries > 0 && error.fberrorCategory != .UserCancelled {
                    self.loginWithFacebookButtonPressed(sender, retries: retries - 1)
                } else {
                    for button in self.buttons {
                        button.enabled = true
                    }
                    self.navigationItem.leftBarButtonItem?.enabled = true
                    switch error.fberrorCategory {
                    case .Server, .AuthenticationReopenSession, .Permissions, .UserCancelled:
                        self.facebookErrorMessage.hidden = false
                    default:
                        self.connectionErrorMessage.hidden = false
                    }
                }
            }
        }
    }

    // MARK: UIViewController

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let unwrappedId = segue.identifier {
            switch unwrappedId {

            case "Sign Up":
                (segue.destinationViewController as! LoginSignupController).facebookUser = sender as? FBGraphObject
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

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
}
