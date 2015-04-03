//
//  LoginEmailController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-12.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class LoginController: UITableViewController, UIAlertViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func cancelButtonPressed(sender: UIBarButtonItem) {
        dismissLoginModalController()
    }

    @IBAction func forgotButtonPressed(sender: UIBarButtonItem) {
        showResetAlertView()
    }

    private func showResetAlertView(message: String? = nil) {
        view.endEditing(true)
        let alertView = UIAlertView(title: NSLocalizedString("LoginController.resetPassword.alert.title", value: "Type your email", comment: "Alert title for when user requests a password reset"), message: message ?? NSLocalizedString("LoginController.resetPassword.alert.message", value: "We will send you a link to reset your password", comment: "Alert message for when user requests a password reset"), delegate: self, cancelButtonTitle: FNLocalizedCancelButtonTitle, otherButtonTitles: NSLocalizedString("LoginController.resetPassword.alert.resetButtonTitle", value: "Reset", comment: "Alert button for reset password"))
        alertView.alertViewStyle = .PlainTextInput
        alertView.textFieldAtIndex(0)?.keyboardType = .EmailAddress
        alertView.show()
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            let email = alertView.textFieldAtIndex(0)?.text

            if email?.fn_count > 0 && email!.isEmail() {

                // Check internet connection
                if Reachability.fn_reachable() {

                    ParseUser.requestPasswordResetForEmailInBackground(email!) { (succeeded, error) -> Void in

                        if error != nil {
                            PFAnalytics.fn_trackErrorInBackground(error, location: .LoginControllerResetPassword)
                            if error.domain == PFParseErrorDomain && error.code == PFErrorCode.ErrorUserWithEmailNotFound.rawValue {
                                FNToast.show(text: NSLocalizedString("LoginController.resetPassword.errorDescription.emailNotFound", value: "There is no user registered with this email", comment: "Message for when there is no user with the email providen error"), type: .Error)
                            } else {
                                FNToast.show(text: FNLocalizedUnknownErrorDescription, type: .Error)
                            }

                        } else {
                            // Success
                            FNToast.show(text: NSLocalizedString("LoginController.resetPassword.successMessage", value: "Password reset instructions sent to your email", comment: "Message for when the email reset was successful"))
                        }
                    }

                } else {
                    FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
                }

            } else {
                showResetAlertView(message: NSLocalizedString("LoginController.resetPassword.errorDescription.emailNotValid", value: "Please, insert a valid email address", comment: "Alert title for when user types an invalid email address"))
            }
        }
    }

    @IBAction func facebookButtonPressed(sender: UIButton) {

        // Check internet connection
        if Reachability.fn_reachable() {
            let loadingView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))

            // Login
            PFFacebookUtils.logInInBackgroundWithReadPermissions(["public_profile", "user_friends", "email"]) { (user, error) -> Void in

                if let parseUser = user as? ParseUser {

                    // Successful login
                    NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)

                    // If user is valid, finish login flow. Otherwise, download information from Facebook and go to next screen.
                    if parseUser.facebookId?.fn_count > 0 && parseUser.isValid {

                        // Go back to primary controller
                        self.dismissLoginModalController()

                    } else {

                        // Get information from Facebook
                        FBSDKGraphRequest(graphPath: "me?fields=id,first_name,email,gender", parameters: nil).startWithCompletionHandler { (requestConnection, result, error) -> Void in

                            // Send Facebook information for review in next screen
                            loadingView.removeFromSuperview()
                            self.performSegueWithIdentifier("Sign Up", sender: result)
                        }
                    }

                } else {

                    // Unsuccessful login
                    loadingView.removeFromSuperview()
                    PFAnalytics.fn_trackErrorInBackground(error ?? NSError(fn_code: .UserCanceled), location: .LoginControllerFacebookLogin)
                    if error != nil {
                        FNToast.show(text: FNLocalizedUnknownErrorDescription, type: .Error)
                    }
                }
            }
        } else {
            FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
        }
    }

    @IBAction func loginButtonPressed(sender: UIButton!) {
        view.endEditing(true)

        // Check vality of fields
        if usernameField.text.fn_count > 0 && passwordField.text.fn_count > 0 {

            // Check internet connection
            if Reachability.fn_reachable() {
                let loadingView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))

                ParseUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) { (user, error) -> Void in

                    if let parseUser = user as? ParseUser {

                        // Successful login
                        NSNotificationCenter.defaultCenter().postNotificationName(LoginChangedNotificationName, object: self)

                        // If user is valid, finish login flow. Otherwise, go to next screen.
                        if parseUser.facebookId?.fn_count > 0 && parseUser.isValid {

                            // Go back to primary controller
                            self.dismissLoginModalController()

                        } else {

                            // Send user for review in next screen
                            loadingView.removeFromSuperview()
                            self.performSegueWithIdentifier("Sign Up", sender: nil)
                        }

                    } else {

                        // Unsuccessful login
                        loadingView.removeFromSuperview()

                        if error != nil {
                            PFAnalytics.fn_trackErrorInBackground(error, location: .LoginControllerPasswordLogin)
                        }

                        if error.code == PFErrorCode.ErrorObjectNotFound.rawValue {
                            FNToast.show(text: NSLocalizedString("LoginController.loginErrorDescription.userNotFound", value: "Username or password incorrect", comment: "Message for when user does not exist or wrong password"), type: .Error)
                        } else {
                            FNToast.show(text: FNLocalizedUnknownErrorDescription, type: .Error)
                        }
                    }
                }
            } else {
                FNToast.show(text: FNLocalizedOfflineErrorDescription, type: .Error)
            }
        } else {
            FNToast.show(text: NSLocalizedString("LoginController.loginErrorDescription.incomplete", value: "Username or password missing", comment: "Message for when user does not fill the fields"), type: .Error)
        }
    }

    // MARK: UIViewController

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let facebookLogin = tableView.tableHeaderView!
        facebookLogin.frame.size.height = view.bounds.height - 240
        tableView.tableHeaderView = facebookLogin
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.fn_trackScreenInBackground("Login: Main", block: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let segueId = segue.identifier {
            switch segueId {

            case "Sign Up":
                if !(sender is UIButton) {
                    segue.destinationViewController.navigationItem.hidesBackButton = true
                    (segue.destinationViewController as SignupController).facebookUser = FacebookUser(graphObject: sender)
                }

            default:
                break
            }
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
}