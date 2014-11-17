//
//  PhotoComparisonController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

internal class PollController: UIViewController {
    
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
    
    var masked = false

    @IBAction func didDrag(sender: UIPanGestureRecognizer) {
        
        switch sender.state {
        case .Possible: // the recognizer has not yet recognized its gesture, but may be evaluating touch events. this is the default state
            break
        case .Began:
            for photoView in [leftPhotoView, rightPhotoView] {
                photoView.layer.zPosition = 0
            }
            sender.view?.layer.zPosition = 1
        case .Changed: // the recognizer has received touches recognized as a change to the gesture. the action method will be called at the next turn of the run loop
            var photoViewFrame = sender.view!.frame
            photoViewFrame.origin.x += sender.translationInView(view).x / 2
            sender.view!.frame = photoViewFrame
        case .Ended: fallthrough
        case .Cancelled: fallthrough
        case .Failed:
            UIView.animateWithDuration(0.15) { () -> Void in
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        }
        
        sender.setTranslation(CGPointZero, inView: view)
    }
    
    func adjustMaskSizeWithAnimationDuration(duration: CFTimeInterval?) {
        
        var photoViewSize = view.bounds.size
        photoViewSize.width /= 2
        
        if duration != nil {
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration!)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
        
        for photoView in [leftPhotoView, rightPhotoView] {
            // 2D scale
            var layerMaskTransform = photoView.layer.mask.transform
            layerMaskTransform.m11 = photoViewSize.width
            layerMaskTransform.m22 = photoViewSize.height
            photoView.layer.mask.transform = layerMaskTransform
        }
        
        if duration != nil {
            CATransaction.commit()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !masked {
            let maskReferenceSize: CGFloat = 1
            let spaceBetween: CGFloat = maskReferenceSize / 100
            
            let rightMaskPath = UIBezierPath()
            rightMaskPath.moveToPoint(CGPoint(x: maskReferenceSize, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / 10) + spaceBetween, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / -10) + spaceBetween, y: maskReferenceSize))
            rightMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize, y: maskReferenceSize))
            rightMaskPath.closePath()
            let rightMask = CAShapeLayer()
            rightMask.path = rightMaskPath.CGPath
            rightPhotoView.layer.mask = rightMask
            
            let leftMaskPath = UIBezierPath()
            leftMaskPath.moveToPoint(CGPoint(x: 0, y: 0))
            leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize + (maskReferenceSize / 10) - spaceBetween, y: 0))
            leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize - (maskReferenceSize / 10) - spaceBetween, y: maskReferenceSize))
            leftMaskPath.addLineToPoint(CGPoint(x: 0, y: maskReferenceSize))
            leftMaskPath.closePath()
            let leftMask = CAShapeLayer()
            leftMask.path = leftMaskPath.CGPath
            leftPhotoView.layer.mask = leftMask
            
            masked = true
            adjustMaskSizeWithAnimationDuration(nil)
        }
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
