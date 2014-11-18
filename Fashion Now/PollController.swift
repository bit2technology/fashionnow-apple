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

    var photoViews: [UIView]!
    @IBOutlet var leftPhotoView: UIView!
    @IBOutlet var rightPhotoView: UIView!

    @IBAction func didDrag(sender: UIPanGestureRecognizer) {

        func setMaskTranslateX(translate: CGFloat, #view: UIView, #duration: CFTimeInterval?) {
            CATransaction.begin()
            if let unwrappedDuration = duration {
                CATransaction.setAnimationDuration(unwrappedDuration)
            } else {
                CATransaction.setDisableActions(true)
            }

            var layerMaskTransform = view.layer.mask.transform
            layerMaskTransform.m41 = translate
            view.layer.mask.transform = layerMaskTransform

            CATransaction.commit()
        }

        switch sender.state {

        case .Changed:
            let translationX = sender.translationInView(view).x
            let draggingView = (translationX > 0 ? leftPhotoView : rightPhotoView)
            for photoView in photoViews {
                let isDraggingView = (photoView == draggingView)
                photoView.transform = CGAffineTransformMakeTranslation((isDraggingView ? translationX / 2 : 0), 0)
                setMaskTranslateX(translationX / (isDraggingView ? 2 : 1), view: photoView, duration: nil)
            }
        case .Ended: fallthrough
        case .Cancelled: fallthrough
        case .Failed:
            for photoView in photoViews {
                setMaskTranslateX(0, view: photoView, duration: 0.15)
                UIView.animateWithDuration(0.15) { () -> Void in
                    photoView.transform = CGAffineTransformIdentity
                }
            }
        default:
            return
        }


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

    // MARK: Layout

    func adjustMaskSizeWithAnimationDuration(duration: CFTimeInterval) {

        var photoViewSize = view.bounds.size
        photoViewSize.width /= 2

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        for photoView in photoViews {
            photoView.layer.mask.transform = CATransform3DMakeScale(photoViewSize.width, photoViewSize.height, 1)
        }
        CATransaction.commit()
    }

    var masked = false
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !masked {
            let maskReferenceSize: CGFloat = 1
            let spaceBetween: CGFloat = maskReferenceSize / 100
            
            let rightMaskPath = UIBezierPath()
            rightMaskPath.moveToPoint(CGPoint(x: 3 * maskReferenceSize, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / 10) + spaceBetween, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / -10) + spaceBetween, y: maskReferenceSize))
            rightMaskPath.addLineToPoint(CGPoint(x: 3 * maskReferenceSize, y: maskReferenceSize))
            rightMaskPath.closePath()
            let rightMask = CAShapeLayer()
            rightMask.path = rightMaskPath.CGPath
            rightPhotoView.layer.mask = rightMask
            
            let leftMaskPath = UIBezierPath()
            leftMaskPath.moveToPoint(CGPoint(x: -2 * maskReferenceSize, y: 0))
            leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize + (maskReferenceSize / 10) - spaceBetween, y: 0))
            leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize - (maskReferenceSize / 10) - spaceBetween, y: maskReferenceSize))
            leftMaskPath.addLineToPoint(CGPoint(x: -2 * maskReferenceSize, y: maskReferenceSize))
            leftMaskPath.closePath()
            let leftMask = CAShapeLayer()
            leftMask.path = leftMaskPath.CGPath
            leftPhotoView.layer.mask = leftMask
            
            masked = true
            adjustMaskSizeWithAnimationDuration(0)
        }
    }

    // MARK: Rotation

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (context) -> Void in
            self.adjustMaskSizeWithAnimationDuration(context.transitionDuration())
        }, completion: nil)
    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        adjustMaskSizeWithAnimationDuration(duration)
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        photoViews = [leftPhotoView, rightPhotoView]
    }
}
