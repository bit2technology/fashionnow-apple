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
                self.imageView.image = UIImage(data: data)
            }
        }
    }

    var delegate: PhotoControllerDelegate?

    enum Layout {
        case Left, Right
    }
    var layout: Layout = Layout.Left {
        didSet {
            adjustForLayout(layout)
        }
    }

    enum Mode {
        case Edit, Vote
    }
    var mode: Mode = .Edit {
        didSet {
            adjustForMode(mode)
        }
    }

    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var libraryButton: UIButton!
    @IBOutlet var previousButton: UIButton!

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var deleteOrVoteButton: UIButton!
    @IBOutlet var buttonsCenterX: NSLayoutConstraint!

    private func adjustForLayout(layout: Layout) {

        let adjustedMaxConstant = CGFloat(9999)

        switch layout {

        case .Left:
            buttonsCenterX.constant = -adjustedMaxConstant

        case .Right:
            buttonsCenterX.constant = adjustedMaxConstant
        }
    }

    private func adjustForMode(mode: Mode) {

        switch mode {

        case .Edit:
            cameraButton.hidden = false
            libraryButton.hidden = false
            previousButton.hidden = false
            imageView.superview?.hidden = true
            imageView.image = nil
            deleteOrVoteButton.setTitle("Delete", forState: .Normal)

        case .Vote:
            cameraButton.hidden = true
            libraryButton.hidden = true
            previousButton.hidden = true
            imageView.superview?.hidden = false
            deleteOrVoteButton.setTitle("Vote", forState: .Normal)
        }
    }

    @IBAction func deleteOrVoteButtonPressed(sender: UIButton) {

        if mode == .Edit {
            photo.image = nil
            imageView.superview?.hidden = true
            imageView.image = nil
        }
    }

    @IBAction func getImageButtonPressed(sender: UIButton) {

        // Define image source
        var source: UIImagePickerControllerSourceType!
        switch sender {

        case cameraButton:
            // If camera is unavailable, do nothing
            if !UIImagePickerController.isSourceTypeAvailable(.Camera) {
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

    // MARK: Controller lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        photo.uploadedBy = PFUser.currentUser()

        deleteOrVoteButton.superview?.tintColor = UIColor.defaultTintColor().colorWithAlphaComponent(0.6)
        deleteOrVoteButton.layer.shadowColor = UIColor.whiteColor().CGColor
        deleteOrVoteButton.layer.shadowOffset = CGSizeZero
        deleteOrVoteButton.layer.shadowOpacity = 1
        deleteOrVoteButton.layer.shadowRadius = 3

        adjustForMode(mode)
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

        // Get edited or original image
        var image = info[UIImagePickerControllerEditedImage] as UIImage!
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as UIImage!
        }

        // Set photo property
        let imageData = UIImageJPEGRepresentation(image, 0.4)
        photo.image = PFFile(data: imageData, contentType: "image/jpeg")

        imageView.image = image
        imageView.superview?.hidden = false

        // Call delegate
        delegate?.photoController?(self, didEditPhoto: photo)

        // Dismiss
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}

@objc protocol PhotoControllerDelegate {

    optional func photoController(photoController: PhotoController, didEditPhoto photo: Photo)
}