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
            if let imagePath = photo.image?.url {
                // There is an URL. Show image view and load data.
                imageContainerHidden = false
                imageView.setImageWithURL(NSURL(string: imagePath), placeholderImage: nil, completed: { (image, error, imageCacheType, url) -> Void in
                    if let unwrappedImage = image {
                        self.delegate?.photoController?(self, didLoadPhoto: self.photo)
                    } else {
                        self.delegate?.photoController?(self, didFailToLoadPhoto: self.photo, error: error)
                    }
                }, usingActivityIndicatorStyle: .White)
            } else {
                // No URL, hide image view and call delegate.
                imageContainerHidden = true
                let error = NSError() // TODO: Better error
                delegate?.photoController?(self, didFailToLoadPhoto: photo, error: error)
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

    @IBOutlet weak var sendButton: UIButton!

    // MARK: Edition buttons

    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    //@IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    var imageButtonsHidden: Bool = false {
        didSet {
            for button in [cameraButton, libraryButton, /*previousButton,*/ deleteButton] {
                button.hidden = imageButtonsHidden
            }
        }
    }

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

    private func setPhotoImage(image: UIImage) {
        // Set photo properties
        let imageData = image.compressedJPEGData()
        photo.image = PFFile(data: imageData, contentType: "image/jpeg")
        imageView.image = image
        imageContainerHidden = false

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        // Edit only if user has write access
        if !photo.ACL.getWriteAccessForUser(ParseUser.currentUser()) {
            return
        }

        switch sender {
        // Present camera
        case cameraButton:
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .Camera
            presentViewController(imagePickerController, animated: true, completion: nil)
        // Present albuns
        case libraryButton:
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .PhotoLibrary
            presentViewController(imagePickerController, animated: true, completion: nil)
        // Present previous sent photos
//        case previousButton:
//            return
        // Unknown source, do nothing
        default:
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

    // MARK: UIPickerViewDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as UIImage
        setPhotoImage(image)
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: TGCameraDelegate

    func cameraDidTakePhoto(image: UIImage!) {
        setPhotoImage(image)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func cameraDidCancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

@objc protocol PhotoControllerDelegate {

    optional func photoController(photoController: PhotoController, didLoadPhoto photo: ParsePhoto)
    optional func photoController(photoController: PhotoController, didFailToLoadPhoto photo: ParsePhoto, error: NSError)

    optional func photoController(photoController: PhotoController, didEditPhoto photo: ParsePhoto)
}

class PhotoBackgroundView: UIImageView {

    override func tintColorDidChange() {
        super.tintColorDidChange()

        backgroundColor = tintColor
    }
}

extension UIImage {

    func compressedJPEGData(maxSize: CGFloat = 1024, compressionQuality: CGFloat = 0.5) -> NSData {

        let resizeScale = maxSize / max(size.width, size.height)

        var img: UIImage?
        if resizeScale < 1 {
            let resizeRect = CGRect(x: 0, y: 0, width: size.width * resizeScale, height: size.height * resizeScale)
            UIGraphicsBeginImageContext(resizeRect.size)
            drawInRect(resizeRect)
            img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }

        return UIImageJPEGRepresentation(img ?? self, compressionQuality)
    }
}