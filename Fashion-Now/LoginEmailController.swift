//
//  LoginEmailController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-12.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginEmailController: UITableViewController, UIAlertViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBAction func forgotButtonPressed(sender: UIBarButtonItem) {
        view.endEditing(true)
        let alertView = UIAlertView(title: NSLocalizedString("LOGIN_RESET_PASSWORD_TITLE", value: "Type your e-mail", comment: "Alert title for when user requests a password reset"), message: NSLocalizedString("LOGIN_RESET_PASSWORD_MESSAGE", value: "We will send you a link to reset your password", comment: "Alert message for when user requests a password reset"), delegate: self, cancelButtonTitle: LocalizedCancelButtonTitle, otherButtonTitles: NSLocalizedString("LOGIN_RESET_PASSWORD_BUTTON", value: "Reset", comment: "Alert button for reset password"))
        alertView.alertViewStyle = .PlainTextInput
        alertView.textFieldAtIndex(0)?.keyboardType = .EmailAddress
        alertView.show()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            ParseUser.requestPasswordResetForEmailInBackground(alertView.textFieldAtIndex(0)?.text) { (succeeded, error) -> Void in
                if let unwrappedError = error {
                    if unwrappedError.domain == PFParseErrorDomain && (unwrappedError.code == kPFErrorUserWithEmailNotFound || unwrappedError.code == kPFErrorUserEmailMissing) {
                        UIAlertView(title: NSLocalizedString("LOGIN_RESET_EMAIL_NOT_FOUND_TITLE", value: "There is no user registered with this e-mail", comment: "Alert title for when there is no user with the e-mail providen error"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
                    } else {
                        UIAlertView(title: NSLocalizedString("LOGIN_RESET_UNKNOWN_TITLE", value: "Log in impossible", comment: "Alert title for general error"), message: NSLocalizedString("LOGIN_RESET_UNKNOWN_MESSAGE", value: "Are you connected to the Internet?", comment: "Alert message for general error"), delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
                    }
                }
            }
        }
    }

    @IBAction func loginButtonPressed(sender: UIButton) {

        if usernameField.text == nil || countElements(usernameField.text) <= 0 || passwordField.text == nil || countElements(passwordField.text) <= 0 {
            UIAlertView(title: NSLocalizedString("LOGIN_ERROR_INCOMPLETE_TITLE", value: "You must provide both username and password", comment: "Alert title for when user does not fill the fields"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loginButton.setBackgroundImage(UIColor.defaultTintColor().image(), forState: .Normal)

        let tableViewHeaderHeight = view.bounds.height - 450
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: tableViewHeaderHeight))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Login: Password", block: nil)
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }

        return false
    }
}
