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

    @IBAction func forgotButtonPressed(sender: UIBarButtonItem) {
        showResetAlertView()
    }

    private func showResetAlertView(message: String? = nil) {
        view.endEditing(true)
        let alertView = UIAlertView(title: NSLocalizedString("LOGIN_RESET_PASSWORD_TITLE", value: "Type your email", comment: "Alert title for when user requests a password reset"), message: message ?? NSLocalizedString("LOGIN_RESET_PASSWORD_MESSAGE", value: "We will send you a link to reset your password", comment: "Alert message for when user requests a password reset"), delegate: self, cancelButtonTitle: FNLocalizedCancelButtonTitle, otherButtonTitles: NSLocalizedString("LOGIN_RESET_PASSWORD_BUTTON", value: "Reset", comment: "Alert button for reset password"))
        alertView.alertViewStyle = .PlainTextInput
        alertView.textFieldAtIndex(0)?.keyboardType = .EmailAddress
        alertView.show()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            let email = alertView.textFieldAtIndex(0)?.text

            if email == nil || countElements(email!) <= 0 || !email!.isEmail() {
                showResetAlertView(message: NSLocalizedString("LOGIN_RESET_ERROR_EMAIL_NOT_VALID_MESSAGE", value: "Please, insert a valid email address", comment: "Alert title for when user types an invalid email address"))
                return
            }

            ParseUser.requestPasswordResetForEmailInBackground(email!) { (succeeded, error) -> Void in
                if error == nil {
                    FNToast.show(text: NSLocalizedString("LOGIN_RESET_SUCCESS_MESSAGE", value: "Password reset instructions sent to your email", comment: "Message for when the email reset was successful"), type: .Error)
                } else if error.domain == PFParseErrorDomain && error.code == PFErrorCode.ErrorUserWithEmailNotFound.rawValue {
                    FNToast.show(text: NSLocalizedString("LOGIN_RESET_ERROR_EMAIL_NOT_FOUND_MESSAGE", value: "There is no user registered with this email", comment: "Message for when there is no user with the email providen error"), type: .Error)
                } else {
                    FNToast.show(text: NSLocalizedString("LOGIN_RESET_GENERAL_MESSAGE", value: "Please, check your internet connection", comment: "Message for general error, possibly connection related"), type: .Error)
                }
            }
        }
    }

    func alertViewShouldEnableFirstOtherButton(alertView: UIAlertView) -> Bool {
        return alertView.textFieldAtIndex(0)?.text.isEmail() ?? false
    }

    @IBAction func loginButtonPressed(sender: UIButton!) {
        view.endEditing(true)

        // Check vality of fields
        if usernameField.text.fn_count > 0 && passwordField.text.fn_count > 0 {

            // Check internet connection
            if Reachability.reachabilityForInternetConnection().isReachable() {
                let loadingView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))

                ParseUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) { (user, error) -> Void in

                    if let unwrappedUser = user as? ParseUser {
                        // Successful login
                        NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)
                        self.dismissLoginModalController()

                    } else {
                        loadingView.removeFromSuperview()
                        self.usernameField.becomeFirstResponder()

                        if error.code == PFErrorCode.ErrorObjectNotFound.rawValue {
                            FNToast.show(text: NSLocalizedString("LOGIN_ERROR_USER_NOT_FOUNT_MESSAGE", value: "Username or password incorrect", comment: "Message for when user does not exist or wrong password"), type: .Error)
                        } else {
                            FNToast.show(text: FNLocalizedUnknownErrorDescription, type: .Error)
                        }
                    }
                }

            } else {
                FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
            }
        } else {
            FNToast.show(text: NSLocalizedString("LoginController.loginErrorDescription.incomplete", value: "You must provide both username and password", comment: "Message for when user does not fill the fields"), type: .Error)
            return
        }






    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let facebookLogin = tableView.tableHeaderView!
        facebookLogin.frame.size.height = view.bounds.height - 240
        tableView.tableHeaderView = facebookLogin
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.fn_trackScreenInBackground("Login: Password", block: nil)
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {

        case usernameField:
            passwordField.becomeFirstResponder()
        case passwordField:
            loginButtonPressed(nil)
        default:
            textField.resignFirstResponder()
        }

        return false
    }
}
