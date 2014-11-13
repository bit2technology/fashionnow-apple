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
            if let unwrappedPhotos = poll.photos {
                leftPhotoController.photo = unwrappedPhotos[0]
                rightPhotoController.photo = unwrappedPhotos[1]
            }
        }
    }
    
    private(set) var leftPhotoController: PhotoController!
    private(set) var rightPhotoController: PhotoController!

    @IBOutlet var leftPhotoView: UIView!
    @IBOutlet var rightPhotoView: UIView!
    
    var maskReferenceSize: CGFloat = 0
    
    func adjustMaskSizeWithAnimationDuration(duration: Double) {
        let rightPhotoViewSize = rightPhotoView.bounds.size
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        self.rightPhotoView.layer.mask.transform = CATransform3DMakeScale(rightPhotoViewSize.width / maskReferenceSize, rightPhotoViewSize.height / maskReferenceSize, 1)
        CATransaction.commit()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if rightPhotoView.layer.mask == nil {

            let viewSize = view.bounds.size
            maskReferenceSize = max(viewSize.width, viewSize.height)
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
        
        adjustMaskSizeWithAnimationDuration(0)
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        adjustMaskSizeWithAnimationDuration(duration)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) -> Void in
            self.adjustMaskSizeWithAnimationDuration(context.transitionDuration())
        }, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let identifier = segue.identifier {

            switch identifier {

            case "Left Photo Controller":
                leftPhotoController = segue.destinationViewController as PhotoController

            case "Right Photo Controller":
                rightPhotoController = segue.destinationViewController as PhotoController

            default:
                return
            }
        }
    }
}
