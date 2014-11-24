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

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func loginWithFacebookButtonPressed(sender: UIButton) {

        // Set loading interface
        sender.enabled = false
        activityIndicator.startAnimating()

        // Login
        PFFacebookUtils.logInWithPermissions(["public_profile", "user_friends", "email"]) { (user, error) -> Void in
            if let customUser = user as? ParseUser {

                // Successful login. Now get Facebook information.
                let avatarSize = Int(64 * UIScreen.mainScreen().scale)
                FBRequestConnection.startWithGraphPath("me?fields=id,first_name,email,gender,picture.height(\(avatarSize)).width(\(avatarSize)).redirect(false)") { (requestConnection, result, error) -> Void in
                    if error == nil {
                        // Send Facebook information for review in next screen
                        self.performSegueWithIdentifier("Sign Up", sender: result)
                    } else {
                        // TODO: Better Facebook request error handler
                        sender.enabled = true
                        self.activityIndicator.stopAnimating()
                        UIAlertView(title: nil, message: error.localizedDescription, delegate: nil, cancelButtonTitle:"OK").show()
                    }
                }
            } else {
                // TODO: Better login error handler
                sender.enabled = true
                self.activityIndicator.stopAnimating()
                UIAlertView(title: nil, message: error.localizedDescription, delegate: nil, cancelButtonTitle:"OK").show()
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
        // iPhone: portrait only; iPad: all.
        var supportedInterfaceOrientations = UIInterfaceOrientationMask.Portrait
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            supportedInterfaceOrientations = .All
        }
        return Int(supportedInterfaceOrientations.rawValue)
    }
}

// MARK: - Login helpers

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