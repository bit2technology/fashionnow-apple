//
//  LoginEmailController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-12.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginEmailController: UITableViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBAction func loginButtonPressed(sender: UIButton) {

        if usernameField.text == nil || countElements(usernameField.text) <= 0 || passwordField.text == nil || countElements(passwordField.text) <= 0 {
            UIAlertView(title: NSLocalizedString("LOGIN_ERROR_INCOMPLEtE_TITLE", value: "You must provide both username and password", comment: "Alert title for when user does not fill the fields"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
            return
        }

        usernameField.enabled = false
        passwordField.enabled = false
        sender.enabled = false
        navigationItem.hidesBackButton = true
        activityIndicator.startAnimating()
        
        ParseUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) { (user, error) -> Void in

            if let unwrappedUser = user as? ParseUser {
                // Successful login
                NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)
                self.dismissLoginModalController()

            } else {
                self.usernameField.enabled = true
                self.usernameField.becomeFirstResponder()
                self.passwordField.enabled = true
                sender.enabled = true
                self.navigationItem.hidesBackButton = false
                self.activityIndicator.stopAnimating()

                if error.code == kPFErrorObjectNotFound {
                    UIAlertView(title: NSLocalizedString("LOGIN_ERROR_USER_NOT_FOUNT_TITLE", value: "Username or password incorrect", comment: "Alert title for when user does not exist or wrong password"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
                } else {
                    UIAlertView(title: NSLocalizedString("LOGIN_ERROR_UNKNOWN_TITLE", value: "Log in impossible", comment: "Alert title for general error"), message: NSLocalizedString("LOGIN_ERROR_UNKNOWN_MESSAGE", value: "Are you connected to the Internet?", comment: "Alert message for general error"), delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
                }
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let unwrappedId = segue.identifier {
            switch unwrappedId {

            case "Sign Up":
                if let facebookUser = sender as? FBGraphObject {
                    segue.destinationViewController.navigationItem.hidesBackButton = true
                }
            default:
                return
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loginButton.setBackgroundImage(UIColor.defaultTintColor().image(), forState: .Normal)

        let tableViewHeaderHeight = view.bounds.height - 450
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: tableViewHeaderHeight))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Login: Password", block: nil)

        usernameField.becomeFirstResponder()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }
}
