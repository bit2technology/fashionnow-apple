//
//  LoginSignupController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginSignupController: StaticDataTableViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var parseUser: ParseUser?
    var facebookUser: FBGraphObject?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func cancelButtonPressed(sender: UITabBarItem) {
        view.endEditing(true)
        (self.presentingViewController as TabBarController).willDismissLoginController()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    private var barButtonItems: [UIBarButtonItem] {
        get {
            var buttonItems = (navigationItem.leftBarButtonItems as? [UIBarButtonItem]) ?? []
            if let rightButtonItems = navigationItem.rightBarButtonItems as? [UIBarButtonItem] {
                buttonItems.extend(rightButtonItems)
            }
            return buttonItems
        }
    }
    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        // Interface tweak
        for barButtonItem in barButtonItems {
            barButtonItem.enabled = false
        }
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItems = [sender, UIBarButtonItem(customView: activityIndicator)]

        // Dismiss keyboard and disable text fields
        view.endEditing(true)
        for textField in [nameField, locationField, emailField, passwordField] {
            textField.enabled = false
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
        currentUser.password = passwordField.text
        currentUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                (self.presentingViewController as TabBarController).willDismissLoginController()
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                // TODO: Better error handling
                for barButtonItem in self.barButtonItems {
                    barButtonItem.enabled = true
                }
                self.navigationItem.rightBarButtonItems = [sender]
                UIAlertView(title: nil, message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
            }
        }
    }

    @IBOutlet weak var genderCell: UITableViewCell!
    @IBOutlet weak var genderPicker: UIPickerView!
    @IBAction func genderButtonPressed(sender: UIButton) {
        cell(genderCell, setHidden: !cellIsHidden(genderCell))
        reloadDataAnimated(true)
    }

    @IBOutlet weak var birthdayButton: UIButton!
    @IBOutlet weak var birthdayCell: UITableViewCell!
    @IBOutlet weak var birthdayPicker: UIDatePicker!
    @IBAction func birthdayButtonPressed(sender: UIButton) {
        cell(birthdayCell, setHidden: !cellIsHidden(birthdayCell))
        reloadDataAnimated(true)
    }
    @IBAction func birthdayPicerValueDidChange(sender: UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        birthdayButton.setTitle(dateFormatter.stringFromDate(sender.date), forState: .Normal)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setting static table view properties
        insertTableViewRowAnimation = .Middle
        deleteTableViewRowAnimation = .Middle
        cells([genderCell, birthdayCell], setHidden: true)
        reloadDataAnimated(false)

        genderPicker.dataSource = self
        genderPicker.delegate = self

        birthdayPicker.maximumDate = NSDate()

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
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonPressed:")
            // Add cancel button if this is not first edit of profile
            if facebookUser == nil {
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonPressed:")
            }
        } else {
            // If there is no user, just show standard interface (sign up)
            return
        }

        // Fill fields with Parse or Facebook information
        nameField.text = parseUser?.name ?? facebookUser?.first_name
        locationField.text = parseUser?.location
        emailField.text = parseUser?.email ?? facebookUser?.email
        passwordField.placeholder = "Optional" // FIXME: Better handlig password change

        // Avatar
        let facebookId = parseUser?.facebookId ?? facebookUser?.objectId
        if let unwrappedFacebookId = facebookId {
            avatarImageView.setImageWithURL(FacebookHelper.urlForPictureOfUser(id: unwrappedFacebookId, size: Int(64 * UIScreen.mainScreen().scale)), usingActivityIndicatorStyle: .WhiteLarge)
        }
    }

    // UIPickerViewDataSource/Delegate

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return ["female", "male", "other"][row]
    }
}