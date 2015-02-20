//
//  LoginSignupController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginSignupController: UITableViewController {

    private let passwordPlaceholder = "pass"

    var parseUser: ParseUser?
    var facebookUser: FBGraphObject?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationField: UITextField!

    @IBOutlet weak var avatarImageView: UIImageView!

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func cancelButtonPressed(sender: UITabBarItem) {
        // Dismiss keyboard
        view.endEditing(true)

        // Dismiss controller
        (self.presentingViewController as! TabBarController).willDismissLoginController()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {

        // Dismiss keyboard
        view.endEditing(true)

        // Check fields vality

        for label in [nameLabel, emailLabel, usernameLabel, passwordLabel] {
            label.textColor = UIColor.darkTextColor()
        }
        var allFieldsValid = true
        var verifyMessages = [String]()

        // Name
        if nameField.text == nil || count(nameField.text) <= 0 {
            nameLabel.textColor = UIColor.redColor()
            allFieldsValid = false
            verifyMessages += ["Name missing"]
        }

        // Email
        if emailField.text == nil || count(emailField.text) <= 0 {
            emailLabel.textColor = UIColor.redColor()
            allFieldsValid = false
            verifyMessages += ["Email missing"]
        } else if !emailField.text.isEmail() {
            emailLabel.textColor = UIColor.redColor()
            allFieldsValid = false
            verifyMessages += ["Email not valid"]
        }

        // Username
        if usernameField.text == nil || count(usernameField.text) <= 0 {
            usernameLabel.textColor = UIColor.redColor()
            allFieldsValid = false
            verifyMessages += ["Username missing"]
        }

        // Password
        if passwordField.text == nil || count(passwordField.text) < 6 {
            passwordLabel.textColor = UIColor.redColor()
            allFieldsValid = false
            verifyMessages += ["Password missing or too short (6 characters minimum)"]
        }

        // Show alert if one or more fields are not valid
        if !allFieldsValid {
            UIAlertView(title: NSLocalizedString("REVIEW_SIGNUP_INFO_ALERT_TITLE", value: "Review information" , comment: "Title of alert of missing/wrong information"), message: "\n".join(verifyMessages), delegate: nil, cancelButtonTitle: NSLocalizedString("REVIEW_SIGNUP_INFO_ALERT_CANCEL", value: "OK" , comment: "Cancel button of alert of missing/wrong information")).show()
            return
        }

        // Update Parse user info
        let currentUser = ParseUser.currentUser()
        if let unwrappedFacebookUser = facebookUser {
            currentUser.facebookId = unwrappedFacebookUser.objectId
            currentUser.gender = unwrappedFacebookUser.gender // FIXME: Remove gender
        }
        currentUser.name = nameField.text
        currentUser.location = locationField.text
        currentUser.email = emailField.text
        currentUser.username = usernameField.text
        if passwordField.text != passwordPlaceholder {
            currentUser.password = passwordField.text
        }
        currentUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            if !succeeded {
                currentUser.saveEventually(nil)
            }
        }
        // Dismiss controller
        (self.presentingViewController as! TabBarController).willDismissLoginController()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // Adjust layout
        avatarImageView.layer.cornerRadius = 32
        avatarImageView.layer.masksToBounds = true
        
        // Verify if there is a logged user
        let currentUser = ParseUser.currentUser()
        if !PFAnonymousUtils.isLinkedWithUser(currentUser) {
            parseUser = currentUser
        }

        // If there is a user (Parse or Facebook), change interface to "Review" mode
        if parseUser != nil || facebookUser != nil {

            // Change navigation items
            navigationItem.title = NSLocalizedString("SIGNUP_REVIEW_TITLE", value: "Edit Profile", comment: "User logged in with a Facebook account and must review his/her information.")
            navigationItem.hidesBackButton = true

            // Fill fields with Parse or Facebook information
            nameField.text = parseUser?.name ?? facebookUser?.first_name
            locationField.text = parseUser?.location
            emailField.text = parseUser?.email ?? facebookUser?.email

            // Avatar
            let facebookId = parseUser?.facebookId ?? facebookUser?.objectId
            if let unwrappedFacebookId = facebookId {
                avatarImageView.setImageWithURL(FacebookHelper.urlForPictureOfUser(id: unwrappedFacebookId, size: 64), usingActivityIndicatorStyle: .WhiteLarge)
            }

            // Do specift changes if this is not first edit of profile (if there is no facebook user)
            if facebookUser == nil {
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonPressed:")

                usernameField.text = parseUser?.username
                passwordField.text = passwordPlaceholder
            }
        }
    }
}

private extension String {

    func isEmail() -> Bool {
        let regex = NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive, error: nil)
        return regex?.firstMatchInString(self, options: nil, range: NSMakeRange(0, count(self))) != nil
    }
}