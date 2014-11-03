//
//  PhotoComparisonController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit
import QuartzCore

internal class PhotoComparisonController: UIViewController, PhotoControllerDelegate {
    
    var poll: Poll = Poll() {
        didSet {
            let photos = poll.photos
            
            leftPhoto = photos?[0]
            leftPhotoViewController.photo = leftPhoto!
            
            rightPhoto = photos?[1]
            rightPhotoViewController.photo = rightPhoto!
        }
    }

    var delegate: PhotoComparisonControllerDelegate?
    
    var leftPhotoViewController: PhotoController!
    var rightPhotoViewController: PhotoController!

    @IBOutlet var leftPhotoView: UIView!
    @IBOutlet var rightPhotoView: UIView!
    
    var leftPhoto: Photo?
    var rightPhoto: Photo?
    
    var mode: PhotoController.Mode = .Edit {
        didSet {
            leftPhotoViewController.mode = mode
            rightPhotoViewController.mode = mode
        }
    }
    
    let maskReferenceSize: CGFloat = 1024
    
    func adjustMaskSizeWithAnimationDuration() {
        let rightPhotoViewSize = rightPhotoView.bounds.size
        self.rightPhotoView.layer.mask.transform = CATransform3DMakeScale(rightPhotoViewSize.width / maskReferenceSize, rightPhotoViewSize.height / maskReferenceSize, 1)
    }
    
    func clean(#animated: Bool) {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        leftPhotoViewController.layout = .Left
        rightPhotoViewController.layout = .Right
        
        leftPhotoViewController.delegate = self
        rightPhotoViewController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        poll.createdBy = PFUser.currentUser()

        if rightPhotoView.layer.mask == nil {

//            let viewSize = view.bounds.size
//            maskReferenceSize = max(viewSize.width, viewSize.height)
            let pathReferenceSize = maskReferenceSize * 1.5

            let rightMaskPath = UIBezierPath()
            rightMaskPath.moveToPoint(CGPoint(x: pathReferenceSize, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: pathReferenceSize / 15, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: pathReferenceSize / -7.5, y: pathReferenceSize))
            rightMaskPath.addLineToPoint(CGPoint(x: pathReferenceSize, y: pathReferenceSize))
            rightMaskPath.closePath()

            let rightMask = CAShapeLayer()
            rightMask.path = rightMaskPath.CGPath
            rightPhotoView.layer.mask = rightMask
        }
        
        adjustMaskSizeWithAnimationDuration()
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        adjustMaskSizeWithAnimationDuration()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) -> Void in
            self.adjustMaskSizeWithAnimationDuration()
        }, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let identifier = segue.identifier {

            switch identifier {

            case "Left Photo Controller":
                leftPhotoViewController = segue.destinationViewController as PhotoController

            case "Right Photo Controller":
                rightPhotoViewController = segue.destinationViewController as PhotoController

            default:
                return
            }
        }
    }
    
    // MARK: - PhotoControllerDelegate
    
    func photoController(photoController: PhotoController, didEditPhoto photo: Photo) {
        
        switch photoController {
            
        case leftPhotoViewController:
            leftPhoto = photo
            
        case rightPhotoViewController:
            rightPhoto = photo
            
        default:
            return
        }
        
        poll.photos = (leftPhoto != nil && rightPhoto != nil ? [leftPhoto!, rightPhoto!] : nil)
        delegate?.photoComparisonController?(self, didEditPoll: poll)
    }
}

@objc protocol PhotoComparisonControllerDelegate {
    
    optional func photoComparisonController(photoComparisonController: PhotoComparisonController, didEditPoll poll: Poll)
}
