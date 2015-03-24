//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class PhotoController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    var photo: ParsePhoto = ParsePhoto(user: ParseUser.currentUser()) {
        didSet {

            // Editability
            let readonly = !photo.ACL.getWriteAccessForUser(ParseUser.currentUser())
            for button in [cameraButton, libraryButton, deleteButton] {
                button.hidden = readonly
            }

            // Load image
            if let urlString = photo.image?.url {
                imageContainerHidden(false)
                imageView.sd_setImageWithURL(NSURL(string: urlString), completed: { (image, error, cacheType, url) -> Void in
                    if let unwrappedImage = image {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        println("ar \(imageAspectRatio.constant)")
    }

    weak var delegate: PhotoControllerDelegate?

    @IBOutlet weak var imageAspectRatio: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    private func imageContainerHidden(hidden: Bool) {
        imageView.superview?.hidden = hidden
        imageView.superview?.alpha = (hidden ? 0 : 1)
    }

    // MARK: Edition buttons

    @IBOutlet weak var cameraButton, libraryButton, deleteButton: UIButton!

    // MARK: Layout
    
    @IBOutlet weak var deleteButtonCenterX: NSLayoutConstraint!
    enum PhotoControllerLayout {
        case Left, Right
    }
    var layout: PhotoControllerLayout = .Left {
        didSet {
            switch layout {
            case .Left:
                deleteButtonCenterX.constant = -9999
            case .Right:
                deleteButtonCenterX.constant = 9999
            }
        }
    }

    @IBAction func deleteImage(sender: UIButton) {

        // Delete in model
        self.photo.image = nil

        // Delete in view
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            self.imageView.superview!.alpha = 0
        }) { (completed) -> Void in
            self.imageContainerHidden(true)
            self.imageView.image = nil
        }

        // Call delegate
        delegate?.photoEdited(self)
    }

    private func setPhotoImage(image: UIImage) {

        // Set photo properties
        let imageData = image.fn_compressed()
        photo.image = PFFile(name: "image.jpg", data: imageData, contentType: "image/jpeg")
        imageView.image = image
        imageContainerHidden(false)

        // Call delegate
        delegate?.photoEdited(self)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        var souce: UIImagePickerControllerSourceType?

        switch sender {
        // Present camera
        case cameraButton:
            souce = .Camera
        // Present albuns
        case libraryButton:
            souce = .PhotoLibrary
        // Unknown source, do nothing
        default:
            return
        }

        if let pickerSouce = souce {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = pickerSouce
            presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: UIPickerViewDelegate

    private let assetsLibrary = ALAssetsLibrary()

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as UIImage
        setPhotoImage(image)
        dismissViewControllerAnimated(true, completion: nil)

        // Save to Album if source is camera
        if picker.sourceType == .Camera {
            assetsLibrary.saveImage(image, toAlbum: "Fashion Now", completion: nil, failure: nil)
        }
    }
}

/// Photo edition delegate
@objc protocol PhotoControllerDelegate {
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