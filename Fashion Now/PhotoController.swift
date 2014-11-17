//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

private let PhotoControllerWillStartCameraCaptureNotification = "PhotoControllerWillStartCameraCaptureNotification"

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

    @IBOutlet var cameraView: UIView!
    @IBOutlet var imageView: UIImageView!

    func willStartCameraCapture() {
        cameraView.hidden = true
    }

    func deleteImage() {

        // Set photo properties
        photo.image = nil
        imageView.hidden = true
        imageView.image = nil

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        // Define image source
        var source: UIImagePickerControllerSourceType!
        switch sender {
        case cameraButton:
            NSNotificationCenter.defaultCenter().postNotificationName(PhotoControllerWillStartCameraCaptureNotification, object: self, userInfo: nil)
            cameraView.hidden = false
            CameraManager.sharedInstance.addPreviewLayerToView(cameraView)
            return
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

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraView.hidden = true
        imageView.hidden = true

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willStartCameraCapture", name: PhotoControllerWillStartCameraCaptureNotification, object: nil)
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = info[UIImagePickerControllerEditedImage] as UIImage!
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as UIImage!
        }
        
        // Set photo properties
        let imageData = UIImageJPEGRepresentation(image, 0.4) // FIXME: Optimize image
        photo.image = PFFile(data: imageData, contentType: "image/jpeg")
        imageView.image = image
        imageView.hidden = false

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)

        // Dismiss
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}

@objc protocol PhotoControllerDelegate {

    optional func photoController(photoController: PhotoController, didEditPhoto photo: Photo)
}
