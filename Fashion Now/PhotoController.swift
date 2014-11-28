//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class PhotoController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DBCameraViewControllerDelegate {

    var photo: ParsePhoto = ParsePhoto(user: ParseUser.currentUser()) {
        didSet {
            if let imagePath = photo.image?.url {
                // There is an URL. Show image view and load data.
                imageContainerHidden = false
                imageView.setImageWithURL(NSURL(string: imagePath), placeholderImage: nil, completed: { (image, error, imageCacheType, url) -> Void in
                    if let unwrappedImage = image {
                        self.delegate?.photoController?(self, didLoadPhoto: self.photo)
                    } else {
                        self.delegate?.photoController?(self, didFailToLoadPhoto: self.photo, error: error)
                    }
                }, usingActivityIndicatorStyle: .Gray)
            } else {
                // No URL, hide image view.
                imageContainerHidden = true
            }
        }
    }

    weak var delegate: PhotoControllerDelegate?

    @IBOutlet weak var imageView: UIImageView!
    private var imageContainerHidden: Bool = true {
        didSet {
            imageView.superview?.hidden = imageContainerHidden
            imageView.superview?.alpha = (imageContainerHidden ? 0 : 1)
        }
    }

    // MARK: Edition buttons

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    var imageButtonsHidden: Bool = false {
        didSet {
            for button in [cameraButton, previousButton, deleteButton] {
                button.hidden = imageButtonsHidden
            }
        }
    }

    @IBAction func deleteImage(sender: UIButton) {

        // Edit only if user has write access
        if !photo.ACL.getWriteAccessForUser(ParseUser.currentUser()) {
            return
        }

        // Delete in model
        self.photo.image = nil

        // Delete in view
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            self.imageView.superview!.alpha = 0
        }) { (completed) -> Void in
            self.imageContainerHidden = true
            self.imageView.image = nil
        }

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        // Edit only if user has write access
        if !photo.ACL.getWriteAccessForUser(ParseUser.currentUser()) {
            return
        }

        switch sender {
        case cameraButton:
            let cameraContainer = DBCameraContainerViewController(delegate: self)
            cameraContainer.setFullScreenMode()
            let nav = UINavigationController(rootViewController: cameraContainer)
            nav.delegate = self
            nav.navigationBarHidden = true
            presentViewController(nav, animated: true, completion: nil)

        case previousButton:
            // TODO: Previous photos
            return

        default:
            // If unknown source, do nothing
            return
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        deleteButton.tintColor = UIColor.defaultTintColor(alpha: 0.6)
    }

    // MARK: UINavigationControllerDelegate

    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: DBCameraViewControllerDelegate

    func camera(cameraViewController: AnyObject!, didFinishWithImage image: UIImage!, withMetadata metadata: [NSObject : AnyObject]!) {
        // Set photo properties
        let imageData = image.compressedJPEGData()
        photo.image = PFFile(data: imageData, contentType: "image/jpeg")
        imageView.image = image
        imageContainerHidden = false

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)

        // Dismiss
        (cameraViewController as? UIViewController)?.dismissViewControllerAnimated(true, completion: nil)
    }

    func dismissCamera(cameraViewController: AnyObject!) {
        // Dismiss
        (cameraViewController as? UIViewController)?.dismissViewControllerAnimated(true, completion: nil)
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

extension UIImage {

    func compressedJPEGData(compressionQuality: CGFloat = 0.5) -> NSData {

        var actualHeight = size.height
        var actualWidth = size.width
        let maxHeight: CGFloat = 600
        let maxWidth: CGFloat = 800
        var imgRatio = actualWidth / actualHeight
        let maxRatio = maxWidth / maxHeight

        if actualHeight > maxHeight || actualWidth > maxWidth {

            if imgRatio < maxRatio {
                // Adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if imgRatio > maxRatio {
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else{
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }

        let rect = CGRect(x: 0, y: 0, width: actualWidth, height: actualHeight)
        UIGraphicsBeginImageContext(rect.size);
        drawInRect(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext();
        let imageData = UIImageJPEGRepresentation(img, compressionQuality);
        UIGraphicsEndImageContext();

        return imageData
    }
}