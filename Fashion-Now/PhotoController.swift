//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

private let animationDuration: NSTimeInterval = 0.25

class PhotoController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var photo: ParsePhoto = ParsePhoto(user: ParseUser.current()) {
        didSet {

            // Clean
            imageView.image = nil

            // Editability
            let readonly = photo.objectId?.fn_count > 0
            for button in [cameraButton, libraryButton, deleteButton] {
                button.hidden = readonly
            }

            // Load image and present or hide container
            if let urlString = photo.image?.url {

                // Show image container and remove old aspect ratio constraint
                imageContainerHidden(false)

                // Load image
                imageView.sd_setImageWithURL(NSURL(string: urlString), completed: { (image, error, cacheType, url) -> Void in
                    if image != nil {
                        self.imageView.fn_setAspectRatio(image)
                        self.delegate?.photoLoaded(self)
                    } else {
                        self.delegate?.photoLoadFailed(self, error: error)
                    }
                })
            } else {
                imageContainerHidden(true)
            }
        }
    }

    weak var delegate: PhotoControllerDelegate?

    @IBOutlet weak var imageView: UIImageView!
    /// Show or hide image container
    private func imageContainerHidden(hidden: Bool) {
        imageView.superview!.hidden = hidden
        imageView.superview!.alpha = 1
    }

    // MARK: Edition buttons

    @IBOutlet weak var cameraButton, libraryButton, deleteButton: UIButton!

    // MARK: Layout
    
    @IBOutlet weak var deleteButtonCenterX: NSLayoutConstraint!
    /// Defines if the layout should be for the right side or not
    var layoutRight: Bool {
        get {
            return deleteButtonCenterX.constant > 0
        }
        set {
            deleteButtonCenterX.constant = (newValue ? 9999 : -9999)
        }
    }

    @IBAction func deleteImage(sender: UIButton) {

        // Delete in model
        photo.image = nil

        // Delete in view
        UIView.transitionWithView(view, duration: animationDuration, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.photo = ParsePhoto(user: ParseUser.current())
        }, completion: nil)

        // Call delegate
        delegate?.photoEdited(self)
    }

    private func setPhotoImage(image: UIImage) {

        // Set photo properties
        let imageData = image.fn_compressed()
        photo.image = PFFile(fn_imageData: imageData)
        photo.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            if let error = error {
                PFAnalytics.fn_trackErrorInBackground(error, location: "Photo: Save")
            }
        }
        imageView.image = UIImage(data: imageData)
        imageContainerHidden(false)
        imageView.fn_setAspectRatio(nil)

        // Call delegate
        delegate?.photoEdited(self)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        var source: UIImagePickerControllerSourceType!

        switch sender {
        // Present camera
        case cameraButton:
            source = .Camera
        // Present albuns
        case libraryButton:
            source = .PhotoLibrary
        // Unknown source, do nothing
        default:
            return
        }

        if source != nil {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = source
            presentViewController(picker, animated: true, completion: nil)
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: UIPickerViewDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Track image source
        var source = "Library"
        if picker.sourceType == .Camera {
            if picker.cameraDevice == .Rear {
                source = "Camera Rear"
            } else {
                source = "Camera Front"
            }
        }
        PFAnalytics.fn_trackPostInBackground(source)

        // Get and apply edited or original image
        var image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as! UIImage
        setPhotoImage(image)
        dismissViewControllerAnimated(true, completion: nil)

        
        // Save to Album if source is camera
        if picker.sourceType == .Camera {
            ALAssetsLibrary().saveImage(image, toAlbum: FNLocalizedAppName, completion: nil, failure: { (error) -> Void in
                PFAnalytics.fn_trackErrorInBackground(error, location: "Photo: Add To Camera Roll")
            })
        }
    }
}

/// Photo edition delegate
protocol PhotoControllerDelegate: class {
    func photoLoaded(photoController: PhotoController)
    func photoLoadFailed(photoController: PhotoController, error: NSError)
    func photoEdited(photoController: PhotoController)
}

/// View that adjusts background by tint color
class PhotoBackgroundView: UIView {
    override func tintColorDidChange() {
        super.tintColorDidChange()
        backgroundColor = tintColor
    }
}