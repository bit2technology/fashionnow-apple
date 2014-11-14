//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class PhotoController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var photo: Photo = Photo() {
        didSet {
            photo.image?.getDataInBackgroundWithBlock { (data, error) -> Void in
                if let unwrappedData = data {
                    self.imageView.image = UIImage(data: unwrappedData)
                }
            }
        }
    }
    
    var imageButtonsHidden: Bool = true {
        didSet {
            for button in [cameraButton, libraryButton, previousButton] {
                button.hidden = imageButtonsHidden
            }
        }
    }

    weak var delegate: PhotoControllerDelegate?

    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var libraryButton: UIButton!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var imageView: UIImageView!

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
    
    func deleteImage() {
        
        // Set photo properties
        photo.image = nil
        imageView.image = nil
        
        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = info[UIImagePickerControllerEditedImage] as UIImage!
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as UIImage!
        }

        let img = UIImageOrientation(rawValue: 3)
        println("imageorientation \(img))")
        
        
        // Set photo properties
        let imageData = UIImageJPEGRepresentation(image, 0.4) // FIXME: Optimize image
        photo.image = PFFile(data: imageData, contentType: "image/jpeg")
        imageView.image = image

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)

        // Dismiss
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}

@objc protocol PhotoControllerDelegate {

    optional func photoController(photoController: PhotoController, didEditPhoto photo: Photo)
}
