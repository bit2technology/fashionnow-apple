//
//  LoginEditProfileController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-21.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

private let pickerNoneLabel = NSLocalizedString("EditProfileController.picker.none", value: "None", comment: "Gender labels")
private let genderValues = ["male", "female", "other"]
private let genderLabels = [NSLocalizedString("EditProfileController.genders.male", value: "Male", comment: "Gender labels"), NSLocalizedString("EditProfileController.genders.female", value: "Female", comment: "Gender labels"), NSLocalizedString("EditProfileController.genders.other", value: "Other", comment: "Gender labels")]
let labelPlaceholderText = NSLocalizedString("EditProfileController.label.optional", value: "Optional", comment: "Optional field")

class EditProfileController: FNTableController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderField: UILabel!
    private var gender: String? {
        didSet {
            if let genderIndex = find(genderValues, gender ?? "") {
                genderField.textColor = UIColor.fn_tint()
                genderField.text = genderLabels[genderIndex]
            } else {
                genderField.textColor = UIColor.fn_placeholder()
                genderField.text = labelPlaceholderText
            }
        }
    }
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var birthdayField: UILabel!
    private var birthday: NSDate? {
        didSet {
            if let birthday = birthday {
                birthdayField.textColor = UIColor.fn_tint()
                birthdayField.text = birthday.fn_birthdayDescription
            } else {
                birthdayField.textColor = UIColor.fn_placeholder()
                birthdayField.text = labelPlaceholderText
            }
        }
    }
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationField: UITextField!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    private var avatarChanged = false

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
            }, cancelBlock: nil, origin: view)
            if gender != nil {
                genderPicker.addCustomButtonWithTitle(pickerNoneLabel, actionBlock: { () -> Void in
                    self.gender = nil
                    genderPicker.hidePickerWithCancelAction()
                })
            }
            genderPicker.showActionSheetPicker()

        case NSIndexPath(forRow: 2, inSection: 0): // Birthday
            let datePicker = ActionSheetDatePicker(title: nil, datePickerMode: .Date, selectedDate: birthday ?? NSDate(), doneBlock: { (picker, selectedDate, origin) -> Void in
                self.birthday = selectedDate as? NSDate
            }, cancelBlock: nil, origin: view)
            if birthday != nil {
                datePicker.addCustomButtonWithTitle(pickerNoneLabel, actionBlock: { () -> Void in
                    self.birthday = nil
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

        let currentUser = ParseUser.current()

        // Backup old info
        let nameBkp = currentUser.name
        let genderBkp = currentUser.gender
        let birthdayBkp = currentUser.birthday
        let locationBkp = currentUser.location
        let avatarImageBkp = currentUser.avatarImage

        // Update Parse user info
        currentUser.name = self.nameField.fn_text
        currentUser.gender = self.gender
        currentUser.birthday = self.birthday
        currentUser.location = self.locationField.fn_text
        // Set photo properties
        if self.avatarChanged {
            let imageData = self.avatarImageView.image!.scaleToCoverSize(CGSize(width: 256, height: 256)).fn_data(quality: 0.8)
            currentUser.avatarImage = PFFile(fn_imageData: imageData)
        }

        // Update interface
        let activityIndicatorView = navigationController!.view.fn_setLoading(background: UIColor.fn_white(alpha: 0.5))
        currentUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            activityIndicatorView.removeFromSuperview()

            if FNAnalytics.logError(error, location: "EditProfileController: User Save") {
                // Error handling
                if error!.code == PFErrorCode.ErrorConnectionFailed.rawValue {
                    FNToast.show(title: FNLocalizedOfflineErrorDescription, type: .Error)
                } else {
                    FNToast.show(title: FNLocalizedUnknownErrorDescription, type: .Error)
                }

                // Return backup
                currentUser.name = nameBkp
                currentUser.gender = genderBkp
                currentUser.birthday = birthdayBkp
                currentUser.location = locationBkp
                currentUser.avatarImage = avatarImageBkp

                return
            }

            self.dismissLoginModalController()
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let currentUser = ParseUser.current()

        // Adjust layout
        let placeholderImage = UIColor.fn_placeholder().fn_image()
        avatarImageView.image = placeholderImage

        // Fill fields with Parse or Facebook information
        nameField.text = currentUser.name
        gender = currentUser.gender
        birthday = currentUser.birthday
        locationField.text = currentUser.location
        if let unwrappedAvatarUrl = currentUser.avatarURL(size: 84) {
            avatarImageView.setImageWithURL(unwrappedAvatarUrl, placeholderImage: placeholderImage, completed: nil, usingActivityIndicatorStyle: .WhiteLarge)
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {

        case nameField:
            locationField.becomeFirstResponder()
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