//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class PhotoController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, FastttCameraDelegate {

    var photo: ParsePhoto = ParsePhoto(user: ParseUser.current()) {
        didSet {

            // Clean
            bgImageView.image = nil
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
                        self.imageView.fn_setAspectRatio(image: image)
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                            let blurredImage = image.fn_blur()
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.bgImageView.image = blurredImage
                                self.delegate?.photoLoaded(self)
                            })
                        })
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

    @IBOutlet weak var bgImageView, imageView: UIImageView!
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
        view.fn_transition(true, changes: { () -> Void in
            self.photo = ParsePhoto(user: ParseUser.current())
        })

        // Call delegate
        delegate?.photoEdited(self)
    }

    private func setPhotoImage(image: UIImage, source: String) {

        // Set photo properties
        photo.image = PFFile(fn_imageData: image.fn_data())
        photo.saveInBackgroundWithBlock { (succeeded, error) -> Void in
            FNAnalytics.logError(error, location: "Photo: Save")
        }
        imageView.image = image
        imageContainerHidden(false)
        imageView.fn_setAspectRatio(image: nil)

        // Call delegate
        delegate?.photoEdited(self)

        // Analytics
        FNAnalytics.logPhoto(source)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {

        case "Present Camera":
            let fastttCam = (segue.destinationViewController as! CameraController).fasttttCam
            fastttCam.delegate = self
            fastttCam.maxScaledDimension = 1024

        default:
            break
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: UIPickerViewDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get and apply edited or original image
        var image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as! UIImage
        setPhotoImage(image.scaleToFitSize(CGSize(width: 1024, height: 1024)), source: "Library")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: FastttCameraDelegate

    func cameraController(cameraController: FastttCameraInterface!, didFinishCapturingImage capturedImage: FastttCapturedImage!) {
        ALAssetsLibrary().saveImage(capturedImage.fullImage, toAlbum: FNLocalizedAppName, completion: nil, failure: { (error) -> Void in
            FNAnalytics.logError(error, location: "Photo: Add To Camera Roll")
        })
    }

    func cameraController(cameraController: FastttCameraInterface!, didFinishNormalizingCapturedImage capturedImage: FastttCapturedImage!) {
        setPhotoImage(capturedImage.scaledImage, source: cameraController.cameraDevice == .Rear ? "Camera Rear" : "Camera Front")
        dismissViewControllerAnimated(true, completion: nil)
    }
}

/// Photo edition delegate
protocol PhotoControllerDelegate: class {
    func photoLoaded(photoController: PhotoController)
    func photoLoadFailed(photoController: PhotoController, error: NSError)
    func photoEdited(photoController: PhotoController)
}

/// View that adjusts background by tint color
class FNPhotoBackgroundView: UIView {
    override func tintColorDidChange() {
        super.tintColorDidChange()
        backgroundColor = tintColor
    }
}