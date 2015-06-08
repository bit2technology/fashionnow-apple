//
//  LoginEmailController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-12.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class LoginController: FNTableController, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        dismissLoginModalController()
    }

    // MARK: Login with Facebook

    @IBAction func facebookButtonPressed(sender: UIButton) {

        if fn_isOffline() {
            return
        }

        let loadingView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))

        let previousUserId = ParseUser.current().objectId

        // Login
        PFFacebookUtils.facebookLoginManager().loginBehavior = .SystemAccount
        PFFacebookUtils.logInInBackgroundWithReadPermissions(FNFacebookReadPermissions) { (user, error) -> Void in

            if let parseUser = user as? ParseUser {

                // Successful login
                NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)
                if previousUserId == nil || previousUserId == parseUser.objectId {
                    // This is a sign up (first login with Facebook)
                    FNAnalytics.logRegistration("Facebook")
                }

                // Download info from Facebook and return
                parseUser.completeInfoFacebook({ (succeeded, error) -> Void in

                    if succeeded {
                        self.dismissLoginModalController()
                    } else {
                        // Unsuccessful Facebook info completion
                        FNAnalytics.logError(error, location: "Login: Facebook Info")
                        FNToast.show(title: FNLocalizedUnknownErrorDescription, type: .Error)
                    }
                })

            } else {

                // Unsuccessful login
                loadingView.removeFromSuperview()
                FNAnalytics.logError(error ?? NSError(fn_code: .UserCanceled), location: "Login: Facebook")
                if error != nil {
                    FNToast.show(title: FNLocalizedUnknownErrorDescription, type: .Error)
                }
            }
        }
    }

    // MARK: Login with password

    @IBAction func loginButtonPressed(sender: UIButton!) {
        view.endEditing(true)

        // Check vality of fields
        if usernameField.text.fn_count > 0 && passwordField.text.fn_count > 0 {

            if fn_isOffline() {
                return
            }

            let loadingView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))

            ParseUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) { (user, error) -> Void in

                if let parseUser = user as? ParseUser {

                    // Successful login
                    NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)

                    // Go back to primary controller
                    self.dismissLoginModalController()

                } else {

                    // Unsuccessful login
                    loadingView.removeFromSuperview()

                    if FNAnalytics.logError(error, location: "Login: Password") {

                        if error!.domain == PFParseErrorDomain && error!.code == PFErrorCode.ErrorObjectNotFound.rawValue {
                            FNToast.show(title: NSLocalizedString("LoginController.loginErrorDescription.userNotFound", value: "Username or password incorrect", comment: "Message for when user does not exist or wrong password"), type: .Error)
                        }
                    } else {
                        FNToast.show(title: FNLocalizedUnknownErrorDescription, type: .Error)
                    }
                }
            }

        } else {
            FNToast.show(title: NSLocalizedString("LoginController.loginErrorDescription.incomplete", value: "Username or password missing", comment: "Message for when user does not fill the fields"), type: .Error)
        }
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

    // MARK: Reset password

    @IBAction func forgotButtonPressed(sender: UIButton) {
        showResetAlertView()
    }

    private func showResetAlertView(message: String? = nil) {
        view.endEditing(true)

        let alert = SDCAlertController(title: NSLocalizedString("LoginController.resetPassword.alert.title", value: "Type your email", comment: "Alert title for when user requests a password reset"), message: message ?? NSLocalizedString("LoginController.resetPassword.alert.message", value: "We will send you a link to reset your password", comment: "Alert message for when user requests a password reset"), preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.keyboardType = .EmailAddress
        }
        alert.addAction(SDCAlertAction(title: FNLocalizedCancelButtonTitle, style: .Default, handler: nil))
        alert.addAction(SDCAlertAction(title: NSLocalizedString("LoginController.resetPassword.alert.resetButtonTitle", value: "Reset", comment: "Alert button for reset password"), style: .Recommended, handler: { (action) -> Void in
            let email = alert.textFieldAtIndex(0)?.text

            if email?.fn_count > 0 && email!.isEmail() {

                if fn_isOffline() {
                    return
                }

                ParseUser.requestPasswordResetForEmailInBackground(email!) { (succeeded, error) -> Void in

                    if FNAnalytics.logError(error, location: "Login: Reset Password") {

                        if error!.domain == PFParseErrorDomain && error!.code == PFErrorCode.ErrorUserWithEmailNotFound.rawValue {
                            FNToast.show(title: NSLocalizedString("LoginController.resetPassword.errorDescription.emailNotFound", value: "There is no user registered with this email", comment: "Message for when there is no user with the email providen error"), type: .Error)
                        } else {
                            FNToast.show(title: FNLocalizedUnknownErrorDescription, type: .Error)
                        }

                    } else {
                        // Success
                        FNToast.show(title: NSLocalizedString("LoginController.resetPassword.successMessage", value: "Password reset instructions sent to your email", comment: "Message for when the email reset was successful"), type: .Success)
                    }
                }

            } else {
                self.showResetAlertView(message: NSLocalizedString("LoginController.resetPassword.errorDescription.emailNotValid", value: "Please, insert a valid email address", comment: "Alert title for when user types an invalid email address"))
            }
        }))
        alert.presentWithCompletion(nil)
    }
}