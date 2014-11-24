//
//  LoginSignupController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginSignupController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    var parseUser: ParseUser?
    var facebookUser: FBGraphObject?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func cancelButtonPressed(sender: UITabBarItem) {
        (self.presentingViewController as TabBarController).willDismissLoginController()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func doneButtonPressed(sender: UITabBarItem) {
        // Interface tweak
        sender.enabled = false
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityIndicator)

        // Disable text fields
        for textField in [nameField, emailField, passwordField] {
            textField.enabled = false
        }

        // Update Parse user info
        let currentUser = PFUser.currentUser() as ParseUser
        if let unwrappedFacebookUser = facebookUser {
            currentUser.facebookId = unwrappedFacebookUser.objectId
        }
        currentUser.name = nameField.text
        currentUser.email = emailField.text
        currentUser.password = passwordField.text
        currentUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            if succeeded {
                (self.presentingViewController as TabBarController).willDismissLoginController()
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                // TODO: Better error handling
                UIAlertView(title: nil, message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
            }
        }
    }

    @IBOutlet weak var genderPicker: UIPickerView!
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == genderCellIndexPath {
            return genderPickerHidden ? 0 : 162
        }
        if indexPath == NSIndexPath(forRow: 4, inSection: 0) {
            return 0
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    private let birthdayCellIndexPath = NSIndexPath(forRow: 4, inSection: 0)

    private let genderCellIndexPath = NSIndexPath(forRow: 2, inSection: 0)
    var genderPickerHidden: Bool = true {
        didSet {
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
    @IBAction func genderButtonPressed(sender: UIButton) {
        genderPickerHidden = !genderPickerHidden
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        genderPicker.dataSource = self
        genderPicker.delegate = self

        avatarImageView.layer.cornerRadius = 32
        avatarImageView.layer.masksToBounds = true
        
        // Verify if there is a logged user
        let currentUser = PFUser.currentUser() as ParseUser
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
        emailField.text = parseUser?.email ?? facebookUser?.email

        // Avatar
        if let unwrappedFacebookUserPicture = facebookUser?.picturePath {
            FacebookHelper.cachedAvatarPath = unwrappedFacebookUserPicture
        }
        if let unwrappedCachedAvatarPath = FacebookHelper.cachedAvatarPath {
            avatarImageView.setImageWithURL(NSURL(string: unwrappedCachedAvatarPath), usingActivityIndicatorStyle: .Gray)
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