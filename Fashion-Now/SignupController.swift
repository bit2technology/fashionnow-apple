//
//  LoginSignupController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

private let pickerNoneLabel = NSLocalizedString("SignupController.picker.none", value: "None", comment: "Gender labels")
private let genderValues = ["male", "female", "other"]
private let genderLabels = [NSLocalizedString("SignupController.genders.male", value: "Male", comment: "Gender labels"), NSLocalizedString("SignupController.genders.female", value: "Female", comment: "Gender labels"), NSLocalizedString("SignupController.genders.other", value: "Other", comment: "Gender labels")]

class SignupController: FNTableController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate {

    private var registrationMethod: String?

    var facebookUser: FacebookUser?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderField: UILabel!
    private var gender: String?
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var birthdayField: UILabel!
    private var birthday: NSDate?
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
            let genderPicker = ActionSheetStringPicker(title: nil, rows: genderLabels, initialSelection: find(genderValues, gender ?? "") ?? 0, doneBlock: { (picker, selectedIndex, selectedValue) -> Void in
                self.gender = genderValues[selectedIndex]
                self.genderField.text = selectedValue as? String
            }, cancelBlock: nil, origin: view)
            if gender != nil {
                genderPicker.addCustomButtonWithTitle(pickerNoneLabel, actionBlock: { () -> Void in
                    self.gender = nil
                    self.genderField.text = nil
                    genderPicker.hidePickerWithCancelAction()
                })
            }
            genderPicker.showActionSheetPicker()

        case NSIndexPath(forRow: 2, inSection: 0): // Birthday
            let datePicker = ActionSheetDatePicker(title: nil, datePickerMode: .Date, selectedDate: birthday ?? NSDate(), doneBlock: { (picker, selectedDate, origin) -> Void in
                self.birthday = selectedDate as? NSDate // FIXME: Swift 1.2
                self.birthdayField.text = self.birthday?.fn_birthdayDescription
            }, cancelBlock: nil, origin: view)
            if birthday != nil {
                datePicker.addCustomButtonWithTitle(pickerNoneLabel, actionBlock: { () -> Void in
                    self.birthday = nil
                    self.birthdayField.text = nil
                    datePicker.hidePickerWithCancelAction()
                })
            }
            datePicker.showActionSheetPicker()

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

        // Email
        if emailField.fn_text == nil {
            emailLabel.textColor = UIColor.fn_error()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SignupController.saveErrorDescription.emailMissing", value: "E-mail missing", comment: "Error message for Sign Up or Edit Profile"))
        } else if !emailField.text.isEmail() {
            emailLabel.textColor = UIColor.fn_error()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SignupController.saveErrorDescription.emailNotValid", value: "E-mail not valid", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Username
        if usernameField.fn_text == nil {
            usernameLabel.textColor = UIColor.fn_error()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SignupController.saveErrorDescription.usernameMissing", value: "Username missing", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Password
        if !(passwordField.text.fn_count >= 6) {
            passwordLabel.textColor = UIColor.fn_error()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SignupController.saveErrorDescription.passwordTooShort", value: "Password too short (6 characters min.)", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Birthday
        if birthday?.isLaterThan(NSDate().dateBySubtractingYears(4)) == true {
            birthdayLabel.textColor = UIColor.fn_error()
            allFieldsValid = false
            verifyMessages.append(NSLocalizedString("SignupController.saveErrorDescription.userTooYoung", value: "You must be at least 4 years old", comment: "Error message for Sign Up or Edit Profile"))
        }

        // Show alert if one or more fields are not valid
        if !allFieldsValid {
            UIAlertView(title: NSLocalizedString("SignupController.reviewAlert.title", value: "Review information" , comment: "Title of alert of missing/wrong information"), message: "\n".join(verifyMessages), delegate: nil, cancelButtonTitle: FNLocalizedOKButtonTitle).show()
            return
        }

        // Update interface
        let activityIndicatorView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            var error: NSError?
            var currentUser = ParseUser.current()

            /// Present error alert.
            func presentError(error: NSError) {
                activityIndicatorView.removeFromSuperview()
                FNAnalytics.logError(error, location: "Signup: Save")

                // Error handling
                switch error.code {

                case PFErrorCode.ErrorConnectionFailed.rawValue:
                    FNToast.show(title: FNLocalizedOfflineErrorDescription, type: .Error)

                case PFErrorCode.ErrorUsernameTaken.rawValue:
                    self.usernameLabel.textColor = UIColor.fn_error()
                    FNToast.show(title: NSLocalizedString("SignupController.saveErrorDescription.usernameTaken", value: "Username already exists", comment: "Error message for Sign Up or Edit Profile"), type: .Error)

                case PFErrorCode.ErrorUserEmailTaken.rawValue:
                    self.emailLabel.textColor = UIColor.fn_error()
                    FNToast.show(title: NSLocalizedString("SignupController.saveErrorDescription.emailTaken", value: "Another user is using this e-mail", comment: "Error message for Sign Up or Edit Profile"), type: .Error)

                default:
                    FNToast.show(title: FNLocalizedUnknownErrorDescription, type: .Error)
                }
            }

            // If user is not saved yet, save it
            if currentUser.isDirty() {
                currentUser.save(&error)
                if let unwrappedError = error {
                    presentError(unwrappedError)
                    return
                }
            }

            // Get new instance of current user
            let currentUserQuery = PFQuery(className: ParseUser.parseClassName())
            if let unwrappedNewCurrentUser = currentUserQuery.getObjectWithId(currentUser.objectId!, error: &error) as? ParseUser {
                currentUser = unwrappedNewCurrentUser
            } else {
                presentError(error!)
                return
            }

            // Update Parse user info
            currentUser.name = self.nameField.fn_text
            currentUser.gender = self.gender
            currentUser.birthday = self.birthday
            currentUser.location = self.locationField.fn_text
            currentUser.email = self.emailField.text
            currentUser.username = self.usernameField.text
            if self.passwordChanged {
                currentUser.password = self.passwordField.text
                currentUser.hasPassword = true
            }
            if let unwrappedFacebookId = self.facebookUser?.objectId {
                self.registrationMethod = "Facebook"
                currentUser.facebookId = unwrappedFacebookId
            }
            // Set photo properties
            if self.avatarChanged {
                let imageData = self.avatarImageView.image!.fn_compressed(maxSize: 256, compressionQuality: 0.8)
                currentUser.avatarImage = PFFile(fn_imageData: imageData)
            }

            // Save attempt
            currentUser.save(&error)
            if let unwrappedError = error {
                presentError(unwrappedError)
                return
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                FNAnalytics.logRegistration(self.registrationMethod)
                self.dismissLoginModalController()
            })
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let currentUser = ParseUser.current()

        // Adjust layout
        genderField.textColor = UIColor.fn_tint()
        birthdayField.textColor = UIColor.fn_tint()
        avatarImageView.image = UIColor.fn_placeholder().fn_image()

        // The values for gender and birthday are filled with default values (even for anonymous users)
        gender = currentUser.gender ?? facebookUser?.gender
        if let genderIndex = find(genderValues, gender ?? "") {
            genderField.text = genderLabels[genderIndex]
        } else {
            genderField.text = nil
        }
        // Birthday adjusted to GMT
        birthday = currentUser.birthday
        birthdayField.text = birthday?.fn_birthdayDescription

        // If user is anonymous, show standard (empty) controller
        if PFAnonymousUtils.isLinkedWithUser(currentUser) {
            registrationMethod = "Email"
            return
        }

        // Change navigation items
        navigationItem.title = NSLocalizedString("SIGNUP_REVIEW_TITLE", value: "Edit Profile", comment: "User logged in with a Facebook account and must review his/her information.")

        // Fill fields with Parse or Facebook information
        // Name
        nameField.text = currentUser.name ?? facebookUser?.first_name
        // Location
        locationField.text = currentUser.location
        // Email
        emailField.text = currentUser.email ?? facebookUser?.email
        // Avatar
        if let unwrappedAvatarUrl = currentUser.avatarURL(size: 84) {
            avatarImageView.setImageWithURL(unwrappedAvatarUrl, placeholderImage: UIColor.fn_placeholder().fn_image(), completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }

        // Make some changes if user has already configured account
        if currentUser.isValid {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonPressed:")
            usernameField.text = currentUser.username
            passwordField.text = "passwo" // Placeholder
        }
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
        var image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as! UIImage
        avatarImageView.image = image
        avatarChanged = true
        dismissViewControllerAnimated(true, completion: nil)

        // Save to Album if source is camera
        if picker.sourceType == .Camera {
            ALAssetsLibrary().saveImage(image, toAlbum: FNLocalizedAppName, completion: nil, failure: nil)
        }
    }
}

private extension UITextField {
    /// Returns nil if text == ""
    var fn_text: String? {
        return text.fn_count > 0 ? text : nil
    }
}