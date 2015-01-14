//
//  LoginController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-08.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginFacebookController: UIViewController, UINavigationControllerDelegate {

    @IBAction func showBetaWarning(sender: AnyObject) {
        UIAlertView(title: NSLocalizedString("BETA_WARNING_ALERT_TITLE", value: "Fashion Now Beta", comment: "Title in alert warning users about beta limitations"), message: NSLocalizedString("BETA_WARNING_ALERT_MESSAGE", value: "We're sorry, but in this version of Fashion Now, you can only log in with your Facebook account.", comment: "Message in alert warning users about beta limitations"), delegate: nil, cancelButtonTitle: NSLocalizedString("BETA_WARNING_ALERT_CANCEL_BUTTON", value: "OK", comment: "Dismiss alert")).show()
    }

    @IBAction func cancelButtonPressed(sender: UITabBarItem) {
        (self.presentingViewController as TabBarController).willDismissLoginController()
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBOutlet var buttons: [UIButton]!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    /// Label with connection related errors
    @IBOutlet weak var connectionErrorMessage: UILabel!
    /// Label with Facebook/server related errors
    @IBOutlet weak var facebookErrorMessage: UILabel!
    @IBAction func loginWithFacebookButtonPressed(sender: UIButton) {
        loginWithFacebookButtonPressed(sender, countdown: 1)
    }
    func loginWithFacebookButtonPressed(sender: UIButton, countdown: Int) {

        // Set loading interface
        for button in buttons {
            button.enabled = false
        }
        navigationItem.leftBarButtonItem?.enabled = false
        activityIndicator.startAnimating()
        // Hide error messages
        connectionErrorMessage.hidden = true
        facebookErrorMessage.hidden = true

        // Login
        PFFacebookUtils.logInWithPermissions(["public_profile", "user_friends", "email"]) { (user, error) -> Void in
            if let customUser = user as? ParseUser {

                // Successful login
                NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)

                // Get user's Facebook information
                FBRequestConnection.startWithGraphPath("me?fields=id,first_name,email,gender") { (requestConnection, result, error) -> Void in
                    // Send Facebook information for review in next screen
                    self.performSegueWithIdentifier("Sign Up", sender: result)
                }
            } else {

                // Unsuccessful. The user might have disabled Fashion Now app in Facebook. In this case, the SDK needs to try to connect once, to clean token. That's why the app tries to connect to Facebook twice, unless user has explicitly rejected.
                if countdown > 0 && error.fberrorCategory != .UserCancelled {
                    self.loginWithFacebookButtonPressed(sender, countdown: countdown - 1)
                } else {
                    for button in self.buttons {
                        button.enabled = true
                    }
                    self.navigationItem.leftBarButtonItem?.enabled = false
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
                (segue.destinationViewController as LoginSignupController).facebookUser = sender as? FBGraphObject
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
