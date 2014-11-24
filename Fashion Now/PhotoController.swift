//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class PhotoController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var photo: ParsePhoto = ParsePhoto() {
        didSet {
            if let imagePath = photo.image?.url {
                imageContainerHidden = false
                imageView.setImageWithURL(NSURL(string: imagePath), placeholderImage: nil, completed: { (image, error, imageCacheType, url) -> Void in
                    if let unwrappedImage = image {
                        self.delegate?.photoController?(self, didLoadPhoto: self.photo)
                    } else {
                        self.delegate?.photoController?(self, didFailToLoadPhoto: self.photo, error: error)
                    }
                }, usingActivityIndicatorStyle: .Gray)
            } else {
                imageContainerHidden = true
            }
        }
    }

    weak var delegate: PhotoControllerDelegate?

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    var imageButtonsHidden: Bool = false {
        didSet {
            for button in [cameraButton, libraryButton, previousButton, deleteButton] {
                button.hidden = imageButtonsHidden
            }
        }
    }

    @IBAction func deleteImage(sender: UIButton) {

        // Set photo properties
        photo.image = nil
        imageContainerHidden = true
        imageView.image = nil

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        // Define image source
        var source: UIImagePickerControllerSourceType!
        switch sender {
        case cameraButton:
            // If camera is unavailable, do nothing
            if !UIImagePickerController.isSourceTypeAvailable(.Camera) {
                // TODO: Error handling
                return
            }
            source = .Camera

        case libraryButton:
            source = .PhotoLibrary
        case previousButton:
            // TODO: Previous photos
            return
        default:
            // If unknown source, do nothing
            return
        }

        // If camera or photo library
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = source
        presentViewController(imagePickerController, animated: true, completion: nil)
    }

    @IBOutlet weak var imageView: UIImageView!
    var imageContainerHidden: Bool = true {
        didSet {
            imageView.superview?.hidden = imageContainerHidden
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        deleteButton.tintColor = UIColor.defaultTintColor(alpha: 0.6)
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = info[UIImagePickerControllerEditedImage] as UIImage!
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as UIImage!
        }
        
        // Set photo properties
        let imageData = UIImageJPEGRepresentation(image, 0.85) // FIXME: Optimize image
        photo.image = PFFile(data: imageData, contentType: "image/jpeg")
        imageView.image = image
        imageContainerHidden = false

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)

        // Dismiss
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}

@objc protocol PhotoControllerDelegate {

    optional func photoController(photoController: PhotoController, didLoadPhoto photo: ParsePhoto)
    optional func photoController(photoController: PhotoController, didFailToLoadPhoto photo: ParsePhoto, error: NSError)

    optional func photoController(photoController: PhotoController, didEditPhoto photo: ParsePhoto)
}

class PhotoBackgroundView: UIView {

    override func tintColorDidChange() {
        super.tintColorDidChange()

        backgroundColor = tintColor
    }
}
