//
//  LoginSignupController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class LoginSignupController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    private let passwordPlaceholder = "pass"

    let parseUser = ParseUser.currentUser()
    var facebookUser: FBGraphObject?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationField: UITextField!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordVerifyLabel: UILabel!
    @IBOutlet weak var passwordVerifyField: UITextField!

    @IBAction func cancelButtonPressed(sender: UITabBarItem) {
        // Dismiss keyboard
        view.endEditing(true)

        // Dismiss controller
        (presentingViewController as! TabBarController).willDismissLoginController()
        dismissViewControllerAnimated(true, completion: nil)
    }

    let assetsLibrary = ALAssetsLibrary()
    var sourceIsCamera = false
    @IBAction func imageButtonPressed(sender: UIButton) {

        var imagePickerSouce: UIImagePickerControllerSourceType?

        switch sender {
            // Present camera
        case cameraButton:
            imagePickerSouce = .Camera
            sourceIsCamera = true
            // Present albuns
        case libraryButton:
            imagePickerSouce = .PhotoLibrary
            sourceIsCamera = false
            // Unknown source, do nothing
        default:
            return
        }

        if let unwrappedImagePickerSource = imagePickerSouce {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = unwrappedImagePickerSource
            presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }

    private func setPhotoImage(image: UIImage) {
        // Set photo properties
        let imageData = image.compressedJPEGData()
        let avatar = ParsePhoto(user: parseUser)
        avatar.image = PFFile(data: imageData, contentType: "image/jpeg")
        parseUser.avatar = avatar
        avatarImageView.image = image
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
            nameLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_NAME_MISSING", value: "Name missing", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Email
        if emailField.text == nil || count(emailField.text) <= 0 {
            emailLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_EMAIL_MISSING", value: "E-mail missing", comment: "Error message for Sign Up or Edit Profile"))
        } else if !emailField.text.isEmail() {
            emailLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_EMAIL_NOT_VALID", value: "E-mail not valid", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Username
        if usernameField.text == nil || count(usernameField.text) <= 0 {
            usernameLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_USERNAME_MISSING", value: "Username missing", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Password
        if passwordField.text != passwordPlaceholder && (passwordField.text == nil || count(passwordField.text) < 6) {
            passwordLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_PASSWORD_TOO_SHORT", value: "Password too short (6 characters minimum)", comment: "Error message for Sign Up or Edit Profile"))
        }
        // Password verify
        else if passwordField.text != passwordVerifyField.text {
            passwordVerifyLabel.textColor = UIColor.defaultErrorColor()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SIGNUP_ERROR_PASSWORD_DIFFERENT", value: "Password verification failed", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Show alert if one or more fields are not valid
        if !allFieldsValid {
            UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_ALERT_TITLE", value: "Review information" , comment: "Title of alert of missing/wrong information"), message: "\n".join(verifyMessages), delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
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

        // Update Parse user info
        parseUser.name = nameField.text
        parseUser.location = locationField.text
        parseUser.email = emailField.text
        parseUser.username = usernameField.text
        if passwordField.text != passwordPlaceholder {
            parseUser.password = passwordField.text
            parseUser.hasPassword = true
        }
        parseUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in

            if succeeded {
                // Dismiss controller
                (self.presentingViewController as! TabBarController).willDismissLoginController()
                self.dismissViewControllerAnimated(true, completion: nil)

            } else {
                // Revert interface
                self.navigationItem.setRightBarButtonItem(doneButtonItem, animated: true)
                self.navigationItem.setHidesBackButton(hidesBackButton, animated: true)
                self.navigationItem.leftBarButtonItem?.enabled = true
                for button in [self.cameraButton, self.libraryButton] {
                    button.enabled = true
                }
                // Error handling
                if error.code == kPFErrorConnectionFailed {
                    UIAlertView(title: NSLocalizedString("SIGNUP_CONNECTION_FAILED", value: "Connection failed. Are you connected to internet?", comment: "Error message for Sign Up or Edit Profile"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()

                } else if error.code == kPFErrorUsernameTaken {
                    self.usernameLabel.textColor = UIColor.defaultErrorColor()
                    UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_USERNAME_TAKEN", value: "Username already exists", comment: "Error message for Sign Up or Edit Profile"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()

                } else if error.code == kPFErrorUserEmailTaken {
                    self.emailLabel.textColor = UIColor.defaultErrorColor()
                    UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_EMAIL_TAKEN", value: "Another user is using this e-mail", comment: "Error message for Sign Up or Edit Profile"), message: nil, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()

                } else {
                    UIAlertView(title: NSLocalizedString("SIGNUP_ERROR_UNKNOWN", value: "Sorry, there was an error", comment: "Error message for Sign Up or Edit Profile"), message: error.localizedDescription, delegate: nil, cancelButtonTitle: LocalizedOKButtonTitle).show()
                }
            }
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // Adjust layout
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.layer.masksToBounds = true

        // If user is anonymous, show standard (empty) controller
        if PFAnonymousUtils.isLinkedWithUser(parseUser) {
            return
        }

        // Change navigation items
        navigationItem.title = NSLocalizedString("SIGNUP_REVIEW_TITLE", value: "Edit Profile", comment: "User logged in with a Facebook account and must review his/her information.")

        // Fill fields with Parse or Facebook information
        // Name
        nameField.text = parseUser?.name ?? facebookUser?.first_name
        // Location
        locationField.text = parseUser?.location
        // Email
        emailField.text = parseUser?.email ?? facebookUser?.email
        // Avatar
        if let unwrappedAvatarPhoto = parseUser.avatar {
            unwrappedAvatarPhoto.fetchIfNeededInBackgroundWithBlock { (fetchedAvatarPhoto, error) -> Void in
                if let unwrappedFetchedAvatarPhoto = fetchedAvatarPhoto as? ParsePhoto {
                    self.avatarImageView.setImageWithURL(NSURL(string: unwrappedFetchedAvatarPhoto.image!.url!), usingActivityIndicatorStyle: .WhiteLarge)
                }
            }
        } else if let unwrappedFacebookId = (parseUser?.facebookId ?? facebookUser?.objectId) {
            avatarImageView.setImageWithURL(FacebookHelper.urlForPictureOfUser(id: unwrappedFacebookId, size: 84), usingActivityIndicatorStyle: .WhiteLarge)
        }

        // Make some changes if this is first edit after login with Facebook
        if let unwrappedFacebookUser = facebookUser {

            navigationItem.hidesBackButton = true
            parseUser.facebookId = unwrappedFacebookUser.objectId
            parseUser.gender = unwrappedFacebookUser.gender // FIXME: Remove gender
        }

        // Make some changes if user has already configured account
        if parseUser.hasPassword == true {

            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonPressed:")
            usernameField.text = parseUser?.username
            passwordField.text = passwordPlaceholder
            passwordVerifyField.text = passwordPlaceholder
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: UIPickerViewDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as! UIImage
        setPhotoImage(image)
        dismissViewControllerAnimated(true, completion: nil)

        // Save to Album if source is camera
        if sourceIsCamera {
            assetsLibrary.saveImage(image, toAlbum: "Fashion Now", completion: nil, failure: nil)
        }
    }
}

private extension String {

    func isEmail() -> Bool {
        let regex = NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive, error: nil)
        return regex?.firstMatchInString(self, options: nil, range: NSMakeRange(0, count(self))) != nil
    }
}