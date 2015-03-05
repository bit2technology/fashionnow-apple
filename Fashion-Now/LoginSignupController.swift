//
//  LoginSignupController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginSignupController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    private let genderValues = ["male", "female", "other"]
    private let genderLabels = [NSLocalizedString("GENDER_MALE", value: "Male", comment: "Gender labels"), NSLocalizedString("GENDER_FEMALE", value: "Female", comment: "Gender labels"), NSLocalizedString("GENDER_OTHER", value: "Other", comment: "Gender labels")]

    var facebookUser: FBGraphObject?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderField: UILabel!
    private var gender: String!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var birthdayField: UILabel!
    private var birthday: NSDate!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationField: UITextField!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    private var avatarChanged = false

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    private var passwordChanged = false

    @IBAction func cancelButtonPressed(sender: UITabBarItem) {
        // Dismiss keyboard
        view.endEditing(true)
        // Dismiss controller
        dismissLoginModalController()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        // Deselect row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        // Dismiss keyboard
        view.endEditing(true)

        switch indexPath {

        case NSIndexPath(forRow: 1, inSection: 0): // Gender
            ActionSheetStringPicker.showPickerWithTitle(nil, rows: genderLabels, initialSelection: find(genderValues, gender) ?? genderValues.count - 1, doneBlock: { (picker, selectedIndex, selectedValue) -> Void in
                self.gender = self.genderValues[selectedIndex]
                self.genderField.text = selectedValue as? String
            }, cancelBlock: nil, origin: view)

        case NSIndexPath(forRow: 2, inSection: 0): // Birthday
            let timeZoneIndependentFormatter = NSDateFormatter()
            timeZoneIndependentFormatter.dateFormat = "yyyy-MM-dd"
            timeZoneIndependentFormatter.timeZone = GMTTimeZone
            let adjustedBirthdayString = timeZoneIndependentFormatter.stringFromDate(birthday)
            timeZoneIndependentFormatter.timeZone = nil
            ActionSheetDatePicker.showPickerWithTitle(nil, datePickerMode: .Date, selectedDate: timeZoneIndependentFormatter.dateFromString(adjustedBirthdayString), minimumDate: nil, maximumDate: nil, doneBlock: { (picker, selectedDate, origin) -> Void in
                self.birthday = self.timezoneIndependent(selectedDate as NSDate)
                self.birthdayField.text = self.dateDescription(self.birthday)
            }, cancelBlock: nil, origin: view)

        default:
            break
        }
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        var imagePickerSouce: UIImagePickerControllerSourceType?

        switch sender {

        case cameraButton: // Present camera
            imagePickerSouce = .Camera

        case libraryButton: // Present albuns
            imagePickerSouce = .PhotoLibrary

        default: // Unknown source, do nothing
            return
        }

        if let unwrappedImagePickerSource = imagePickerSouce {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = unwrappedImagePickerSource
            presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }

    /// Method called when user attempts to save changes to user object. First, this checks if all fields are valid, then updates the UI to prevent any change (or inconsistency of information) and then tries to save.
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
        if nameField.text == nil || countElements(nameField.text) <= 0 {
            nameLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_NAME_MISSING", value: "Name missing", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Email
        if emailField.text == nil || countElements(emailField.text) <= 0 {
            emailLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_EMAIL_MISSING", value: "E-mail missing", comment: "Error message for Sign Up or Edit Profile"))
        } else if !emailField.text.isEmail() {
            emailLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_EMAIL_NOT_VALID", value: "E-mail not valid", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Username
        if usernameField.text == nil || countElements(usernameField.text) <= 0 {
            usernameLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_USERNAME_MISSING", value: "Username missing", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Password
        if passwordField.text == nil || countElements(passwordField.text) < 6 {
            passwordLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_PASSWORD_TOO_SHORT", value: "Password too short (6 characters min.)", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Show alert if one or more fields are not valid
        if !allFieldsValid {
            UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_REVIEW_TITLE", value: "Review information" , comment: "Title of alert of missing/wrong information"), message: "\n".join(verifyMessages), delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
            return
        }

        // Update interface
        // Done/Activity Indicator
        let doneButtonItem = navigationItem.rightBarButtonItem
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        let activityItem = UIBarButtonItem(customView: activityIndicator)
        navigationItem.setRightBarButtonItem(activityItem, animated: true)
        // Left Bar Button Item
        let hidesBackButton = navigationItem.hidesBackButton
        navigationItem.setHidesBackButton(false, animated: true)
        navigationItem.leftBarButtonItem?.enabled = false
        // Image buttons
        for button in [cameraButton, libraryButton] {
            button.enabled = false
        }
        // Fields
        for field in [nameField, locationField, emailField, usernameField, passwordField] {
            field.enabled = false
        }
        // Table
        tableView.allowsSelection = false

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            var error: NSError?
            var currentUser = ParseUser.currentUser()

            /// Revert interface to original (enable interactive elements).
            func revertInterface() {
                // Revert interface
                // Buttons
                navigationItem.setRightBarButtonItem(doneButtonItem, animated: true)
                navigationItem.setHidesBackButton(hidesBackButton, animated: true)
                navigationItem.leftBarButtonItem?.enabled = true
                for button in [cameraButton, libraryButton] {
                    button.enabled = true
                }
                // Fields
                for field in [nameField, locationField, emailField, usernameField, passwordField] {
                    field.enabled = true
                }
                // Table
                tableView.allowsSelection = true
            }

            /// Present error alert.
            func presentError(error: NSError) {
                // Error handling
                if error.code == kPFErrorConnectionFailed {
                    UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_CONNECTION_TITLE", value: "Connection failed", comment: "Error message for Sign Up or Edit Profile"), message: NSLocalizedString("SIGNUP_ERROR_CONNECTION_MESSAGE", value: "Are you connected to the Internet?", comment: "Error message for Sign Up or Edit Profile"), delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()

                } else if error.code == kPFErrorUsernameTaken {
                    usernameLabel.textColor = UIColor.defaultErrorColor()
                    UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_USERNAME_TAKEN_TITLE", value: "Username already exists", comment: "Error message for Sign Up or Edit Profile"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()

                } else if error.code == kPFErrorUserEmailTaken {
                    emailLabel.textColor = UIColor.defaultErrorColor()
                    UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_EMAIL_TAKEN_TITLE", value: "Another user is using this e-mail", comment: "Error message for Sign Up or Edit Profile"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()

                } else {
                    UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_UNKNOWN_TITLE", value: "Sorry, there was an error", comment: "Error message for Sign Up or Edit Profile"), message: error.localizedDescription, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
                }
            }

            // If user is not saved yet, save it
            if currentUser.isDirty() {
                currentUser.save(&error)
                if let unwrappedError = error {
                    revertInterface()
                    presentError(unwrappedError)
                    return
                }
            }

            // Get new instance of current user
            let currentUserQuery = PFQuery(className: ParseUser.parseClassName())
            if let unwrappedNewCurrentUser = currentUserQuery.getObjectWithId(ParseUser.currentUser().objectId, error: &error) as? ParseUser {
                currentUser = unwrappedNewCurrentUser
            } else {
                revertInterface()
                presentError(error!)
                return
            }

            // Update Parse user info
            currentUser.name = self.nameField.text
            currentUser.gender = self.gender
            currentUser.birthday = self.birthday
            currentUser.location = self.locationField.text
            currentUser.email = self.emailField.text
            currentUser.username = self.usernameField.text
            if self.passwordChanged {
                currentUser.password = self.passwordField.text
                currentUser.hasPassword = true
            }
            if let unwrappedFacebookId = self.facebookUser?.objectId {
                currentUser.facebookId = unwrappedFacebookId
            }
            // Set photo properties
            if self.avatarChanged {
                let imageData = self.avatarImageView.image!.compressedJPEGData()
                let avatar = ParsePhoto(user: currentUser)
                avatar.image = PFFile(data: imageData, contentType: "image/jpeg")
                currentUser.avatar = avatar
            }

            // Save attempt
            currentUser.save(&error)
            if let unwrappedError = error {
                revertInterface()
                presentError(unwrappedError)
                return
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                CRToastManager.showNotificationWithMessage("Teste Toast", completionBlock: { () -> Void in
                    self.dismissLoginModalController()
                })
            })
        }
    }

    /// GMT time zone helper
    private let GMTTimeZone = NSTimeZone(name: "GMT")

    /// This method takes an NSDate in local time and converts it to GMT (without time).
    private func timezoneIndependent(date: NSDate) -> NSDate {
        let timeZoneIndependentFormatter = NSDateFormatter()
        timeZoneIndependentFormatter.dateFormat = "yyyy-MM-dd"
        let adjustedNewBirthdayString = timeZoneIndependentFormatter.stringFromDate(date)
        timeZoneIndependentFormatter.timeZone = GMTTimeZone
        return timeZoneIndependentFormatter.dateFromString(adjustedNewBirthdayString)!
    }

    /// Show description for date in GMT
    private func dateDescription(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = GMTTimeZone
        dateFormatter.dateStyle = .MediumStyle
        return dateFormatter.stringFromDate(birthday)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let currentUser = ParseUser.currentUser()

        // Adjust layout
        genderField.textColor = UIColor.defaultTintColor()
        birthdayField.textColor = UIColor.defaultTintColor()
        avatarImageView.image = UIColor.lightGrayColor().image()
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.layer.masksToBounds = true

        // The values for gender and birthday are filled with default values (even for anonymous users)
        gender = currentUser.gender ?? facebookUser?.gender ?? genderValues.last
        genderField.text = genderLabels[find(genderValues, gender) ?? genderLabels.count - 1]
        // Birthday adjusted to GMT
        birthday = timezoneIndependent(NSDate())
        birthdayField.text = dateDescription(birthday)

        // If user is anonymous, show standard (empty) controller
        if PFAnonymousUtils.isLinkedWithUser(currentUser) {
            return
        }

        // Change navigation items
        navigationItem.title = NSLocalizedString("SIGNUP_REVIEW_TITLE", value: "Edit Profile", comment: "User logged in with a Facebook account and must review his/her information.")

        // Fill fields with Parse or Facebook information
        // Name
        nameField.text = currentUser.name ?? facebookUser?.first_name
        // Birthday
        if let unwrappedUserBirthday = currentUser.birthday {
            birthday = unwrappedUserBirthday
            birthdayField.text = dateDescription(birthday)
        }
        // Location
        locationField.text = currentUser.location
        // Email
        emailField.text = currentUser.email ?? facebookUser?.email
        // Avatar
        if let unwrappedAvatarPhoto = currentUser.avatar {
            unwrappedAvatarPhoto.fetchIfNeededInBackgroundWithBlock { (fetchedAvatarPhoto, error) -> Void in
                if let unwrappedFetchedAvatarPhoto = fetchedAvatarPhoto as? ParsePhoto {
                    self.avatarImageView.setImageWithURL(NSURL(string: unwrappedFetchedAvatarPhoto.image!.url!), usingActivityIndicatorStyle: .WhiteLarge)
                }
            }
        } else if let unwrappedFacebookId = facebookUser?.objectId {
            avatarImageView.setImageWithURL(FacebookHelper.urlForPictureOfUser(id: unwrappedFacebookId, size: 84), usingActivityIndicatorStyle: .WhiteLarge)
        }

        // Make some changes if user has already configured account
        if currentUser.hasPassword == true {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonPressed:")
            usernameField.text = currentUser.username
            passwordField.text = "passwo" // Placeholder
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        PFAnalytics.trackScreenShowInBackground("Login: Signup", block: nil)
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(textField: UITextField) {
        if textField == passwordField {
            passwordChanged = true
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {

        case nameField:
            locationField.becomeFirstResponder()
        case locationField:
            emailField.becomeFirstResponder()
        case emailField:
            usernameField.becomeFirstResponder()
        case usernameField:
            passwordField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }

        return false
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: UIPickerViewDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as UIImage
        avatarImageView.image = image
        avatarChanged = true
        dismissViewControllerAnimated(true, completion: nil)

        // Save to Album if source is camera
        if picker.sourceType == .Camera {
            ALAssetsLibrary().saveImage(image, toAlbum: "Fashion Now", completion: nil, failure: nil)
        }
    }
}