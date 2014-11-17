//
//  PhotoComparisonController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit
import QuartzCore

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
    
    var maskReferenceSize: CGFloat!

    @IBAction func didDragPhotoView(sender: UIPanGestureRecognizer) {
        
        switch sender.state {
        case .Possible: // the recognizer has not yet recognized its gesture, but may be evaluating touch events. this is the default state
            break
        case .Began: // the recognizer has received touches recognized as the gesture. the action method will be called at the next turn of the run loop
            break
        case .Changed: // the recognizer has received touches recognized as a change to the gesture. the action method will be called at the next turn of the run loop
            var photoViewFrame = sender.view!.frame
            photoViewFrame.origin.x += sender.translationInView(view).x / 2
            sender.view!.frame = photoViewFrame
        case .Ended: // the recognizer has received touches recognized as the end of the gesture. the action method will be called at the next turn of the run loop and the recognizer will be reset to UIGestureRecognizerStatePossible
            fallthrough
        case .Cancelled: // the recognizer has received touches resulting in the cancellation of the gesture. the action method will be called at the next turn of the run loop. the recognizer will be reset to UIGestureRecognizerStatePossible
            fallthrough
        case .Failed: // the recognizer has received a touch sequence that can not be recognized as the gesture. the action method will not be called and the recognizer will be reset to UIGestureRecognizerStatePossible
            UIView.animateWithDuration(0.15, animations: { () -> Void in
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            })
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
        
        self.rightPhotoView.layer.mask.transform = CATransform3DMakeScale(photoViewSize.width / maskReferenceSize, photoViewSize.height / maskReferenceSize, 1)
        self.leftPhotoView.layer.mask.transform = CATransform3DMakeScale(photoViewSize.width / maskReferenceSize, photoViewSize.height / maskReferenceSize, 1)
        
        if duration != nil {
            CATransaction.commit()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if maskReferenceSize == nil {
            maskReferenceSize = 1024
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
