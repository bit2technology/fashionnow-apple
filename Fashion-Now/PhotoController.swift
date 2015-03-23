//
//  PhotoController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-20.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class PhotoController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    private let assetsLibrary = ALAssetsLibrary()

    private(set) var imageLoaded = false
    var photo: ParsePhoto = ParsePhoto(user: ParseUser.currentUser()) {
        didSet {
            imageLoaded = false
            if let urlString = photo.image?.url {
                // There is an URL. Show image view and load data.
                imageContainerHidden = false
                imageView.sd_setImageWithURL(NSURL(string: urlString), completed: { (image, error, cacheType, url) -> Void in
                    if let unwrappedImage = image {
                        self.imageLoaded = true
                        self.delegate?.photoControllerDidLoadImage(self)
                    } else {
                        self.delegate?.photoControllerDidFailToLoadImage(self, error: error)
                    }
                })
            } else {
                // No URL, hide image view
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
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    var imageButtonsHidden: Bool = false {
        didSet {
            for button in [cameraButton, libraryButton, deleteButton] {
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
        delegate?.photoControllerDidEditPhoto(self)
    }

    private func setPhotoImage(image: UIImage) {
        // Set photo properties
        let imageData = image.fn_compressed()
        photo.image = PFFile(name: "image.jpg", data: imageData, contentType: "image/jpeg")
        imageView.image = image
        imageContainerHidden = false

        // Call delegate
        delegate?.photoControllerDidEditPhoto(self)
    }

    @IBAction func imageButtonPressed(sender: UIButton) {

        // Edit only if user has write access
        if !photo.ACL.getWriteAccessForUser(ParseUser.currentUser()) {
            return
        }

        var imagePickerSouce: UIImagePickerControllerSourceType?

        switch sender {
        // Present camera
        case cameraButton:
            imagePickerSouce = .Camera
        // Present albuns
        case libraryButton:
            imagePickerSouce = .PhotoLibrary
        // Unknown source, do nothing
        default:
            return
        }

        if let unwrappedImagePickerSource = imagePickerSouce {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = unwrappedImagePickerSource
            presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        deleteButton.tintColor = UIColor.fn_tint(alpha: 0.6)
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

        // Save to Album if source is camera
        if picker.sourceType == .Camera {
            assetsLibrary.saveImage(image, toAlbum: "Fashion Now", completion: nil, failure: nil)
        }
    }
}

@objc protocol PhotoControllerDelegate {

    func photoControllerDidLoadImage(photoController: PhotoController)
    func photoControllerDidFailToLoadImage(photoController: PhotoController, error: NSError)

    func photoControllerDidEditPhoto(photoController: PhotoController)
}

class PhotoBackgroundView: UIImageView {

    override func tintColorDidChange() {
        super.tintColorDidChange()

        backgroundColor = tintColor
    }
}