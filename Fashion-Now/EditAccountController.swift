//
//  EditAccountController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-05-20.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

class EditAccountController: FNTableController, UITextFieldDelegate {

    private var isSignup = false

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    private var passwordChanged = false
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var confirmField: UITextField!

    @IBAction func submit(sender: UIBarButtonItem?) {
        view.endEditing(true)

        let currentUser = ParseUser.current()

        func showError(message: String) {
            FNToast.show(title: NSLocalizedString("EditAccountController.reviewAlert.title", value: "Review information" , comment: "Title of alert of missing/wrong information"), message: message, type: .Warning, position: .Bottom)
        }

        if fn_isOffline(.Bottom) {
            return
        }

        // Check fields vality

        for label in [emailLabel, usernameLabel, passwordLabel, confirmLabel] {
            label.textColor = UIColor.darkTextColor()
        }

        // Email
        if emailField.fn_text == nil || !emailField.text!.isEmail() {
            emailLabel.textColor = UIColor.fn_error()
            showError(NSLocalizedString("EditAccountController.saveErrorDescription.emailNotValid", value: "You must provide a valid e-mail.", comment: "Error message for Sign Up or Edit Profile"))
            return
        }

        // Username
        if !(usernameField.text!.characters.count >= 6) {
            usernameLabel.textColor = UIColor.fn_error()
            showError(NSLocalizedString("EditAccountController.saveErrorDescription.usernameMissing", value: "Your username must have at least 6 characters.", comment: "Error message for Sign Up or Edit Profile"))
            return
        }

        if isSignup || passwordChanged || currentUser.unsavedPassword {
            // Password
            if !(passwordField.text!.characters.count >= 6) {
                passwordLabel.textColor = UIColor.fn_error()
                showError(NSLocalizedString("EditAccountController.saveErrorDescription.passwordTooShort", value: "Your password must have at least 6 characters.", comment: "Error message for Sign Up or Edit Profile"))
                return
            }
            // Confirm
            if (passwordField.text != confirmField.text) {
                confirmLabel.textColor = UIColor.fn_error()
                showError(NSLocalizedString("EditAccountController.saveErrorDescription.passwordTooShort", value: "The password confirmation is different.", comment: "Error message for Sign Up or Edit Profile"))
                return
            }
        }

        let activityIndicatorView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(0.5))
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in

            /// Present error alert.
            func handleError(error: NSError) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in

                    activityIndicatorView.removeFromSuperview()

                    // Error handling
                    switch error.code {

                    case PFErrorCode.ErrorConnectionFailed.rawValue:
                        FNToast.show(title: FNLocalizedOfflineErrorDescription, type: .Warning, position: .Bottom)

                    case PFErrorCode.ErrorUsernameTaken.rawValue:
                        self.usernameLabel.textColor = UIColor.fn_error()
                        showError(NSLocalizedString("EditAccountController.saveErrorDescription.usernameTaken", value: "Another user is already using this username.", comment: "Error message for Sign Up or Edit Profile"))

                    case PFErrorCode.ErrorUserEmailTaken.rawValue:
                        self.emailLabel.textColor = UIColor.fn_error()
                        showError(NSLocalizedString("EditAccountController.saveErrorDescription.emailTaken", value: "Another user is already using this e-mail.", comment: "Error message for Sign Up or Edit Profile"))

                    default:
                        FNToast.show(title: FNLocalizedUnknownErrorDescription, type: .Warning, position: .Bottom)
                    }

                })
            }

            // Update Parse user info
            currentUser.email = self.emailField.text
            currentUser.username = self.usernameField.text
            if self.passwordChanged {
                currentUser.unsavedPassword = true
                currentUser.password = self.passwordField.text
                currentUser.hasPassword = true
            }

            do {
                try currentUser.save()
                currentUser.unsavedPassword = false
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.isSignup {
                        FNAnalytics.logRegistration("Email")
                    }
                    self.dismissLoginModalController()
                })
            } catch {
                FNAnalytics.logError(error as NSError, location: "EditAccountController: User Save")
                handleError(error as NSError)
            }
        }
    }

    @IBAction func cancel(sender: UIBarButtonItem) {
        view.endEditing(true)
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let currentUser = ParseUser.current()
        if currentUser.isLogged {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
            emailField.text = currentUser.email
            usernameField.text = currentUser.username
            if currentUser.hasPassword && !currentUser.unsavedPassword {
                for field in [passwordField, confirmField] {
                    field.text = "passwo" // Placeholder
                }
            }
        } else {
            navigationItem.title = NSLocalizedString("EditAccountController.signup.navTitle", value: "Sign Up", comment: "Title for when controller is in Sign Up mode (user is not logged)")
            isSignup = true
        }

        for field in [emailField, usernameField, passwordField, confirmField] {
            field.delegate = self
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(textField: UITextField) {
        TSMessage.dismissActiveNotification()

        if !passwordChanged && (textField == passwordField || textField == confirmField) {
            passwordChanged = true
            for field in [passwordField, confirmField] {
                field.text = nil
            }
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {

        case emailField:
            usernameField.becomeFirstResponder()
        case usernameField:
            passwordField.becomeFirstResponder()
        case passwordField:
            confirmField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }

        return false
    }
}

private extension UITextField {
    /// Returns nil if text == ""
    var fn_text: String? {
        return text!.characters.count > 0 ? text : nil
    }
}
