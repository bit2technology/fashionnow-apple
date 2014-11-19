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

    var dragEnabled: Bool = true {
        didSet {
            drager.enabled = dragEnabled
        }
    }
    
    private(set) var leftPhotoController: PhotoController!
    private(set) var rightPhotoController: PhotoController!

    private var photoViews: [UIView]!
    @IBOutlet var leftPhotoView: UIView!
    @IBOutlet var rightPhotoView: UIView!
    @IBOutlet var containerView: UIView!

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

    // MARK: Vote animation

    private func animateAndVote(#index: Int, easeIn: Bool) {
        println("vote: \(index)")
        var rate: CGFloat!
        switch index {
        case 0:
            rate = 1
        case 1:
            rate = -1
        default:
            return
        }
        adjustVoteLayout(rate, animationTimingFunction: CAMediaTimingFunction(name: (easeIn ? kCAMediaTimingFunctionEaseInEaseOut : kCAMediaTimingFunctionEaseOut)))
    }

    @IBAction func didDoubleTap(sender: UITapGestureRecognizer) {

        var index: Int!
        
        switch sender.view! {
        case leftPhotoView:
            index = 0
        case rightPhotoView:
            index = 1
        default:
            return
        }
        
        animateAndVote(index: index, easeIn: true)
    }

    @IBOutlet var drager: UIPanGestureRecognizer!
    @IBAction func didDrag(sender: UIPanGestureRecognizer) {

        var translationX = sender.translationInView(containerView).x * 1.6
        let rate = translationX / self.containerView.bounds.width
        
        switch sender.state {
        case .Changed:
            adjustVoteLayout(rate, animationTimingFunction: nil)
        case .Ended:
            let velocityX = sender.velocityInView(containerView).x
            if abs(velocityX) > 1000 {
                animateAndVote(index: (velocityX > 0 ? 0 : 1), easeIn: false)
                return
            }
            if abs(rate) > 0.75 {
                if rate > 0 && velocityX > 0 {
                    animateAndVote(index: 0, easeIn: false)
                    return
                } else if rate < 0 && velocityX < 0 {
                    animateAndVote(index: 1, easeIn: false)
                    return
                }
            }
            fallthrough
        case .Cancelled: fallthrough
        case .Failed:
            adjustVoteLayout(nil, animationTimingFunction: nil)
        default:
            return
        }
    }
    
    private func adjustVoteLayout(rate: CGFloat?, animationTimingFunction: CAMediaTimingFunction?) {
        
        // Helper functions
        
        func setLayerTransform(transform: CATransform3D, toView view: UIView, explicitAnimated animated: Bool) {
            if animated {
                let animation = CABasicAnimation(keyPath: "transform")
                animation.fromValue = NSValue(CATransform3D: view.layer.transform)
                animation.toValue = NSValue(CATransform3D: transform)
                view.layer.addAnimation(animation, forKey: "transform")
            }
            view.layer.transform = transform
        }
        
        func setMaskTranslateX(translate: CGFloat, #view: UIView) {
            var layerMaskTransform = view.layer.mask.transform
            layerMaskTransform.m41 = translate
            view.layer.mask.transform = layerMaskTransform
        }
        
        // If rate == nil, back to original layout animated
        
        if (rate == nil) {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            if let unwrappedAnimationTimingFunction = animationTimingFunction {
                CATransaction.setAnimationTimingFunction(unwrappedAnimationTimingFunction)
            } else {
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
            }
            for photoView in photoViews {
                setLayerTransform(CATransform3DIdentity, toView: photoView, explicitAnimated: true)
                setMaskTranslateX(0, view: photoView)
            }
            CATransaction.commit()
            return
        }
        
        // If rate != nil, adjust layout
        
        var translationX = rate! * containerView.bounds.width / 2
        if abs(rate!) > 1 {
            translationX -= (rate! - (rate > 0 ? 1 : -1)) * containerView.bounds.width / 2 * 0.75
        }
        
        let draggingView = (translationX > 0 ? leftPhotoView : rightPhotoView)
        
        CATransaction.begin()
        if let unwrappedAnimationTimingFunction = animationTimingFunction {
            CATransaction.setAnimationDuration(0.25)
            CATransaction.setAnimationTimingFunction(unwrappedAnimationTimingFunction)
        } else {
            CATransaction.setDisableActions(true)
        }
        for photoView in photoViews {
            let isDraggingView = (photoView == draggingView)
            setLayerTransform(CATransform3DMakeTranslation((isDraggingView ? translationX / 2 : 0), 0, 0), toView: photoView, explicitAnimated: (animationTimingFunction != nil))
            setMaskTranslateX(translationX * (isDraggingView ? 0.75 : 1.25), view: photoView)
        }
        CATransaction.commit()
    }

    // MARK: Layout

    private func adjustMaskSizeWithAnimationDuration(duration: CFTimeInterval) {

        var photoViewSize = containerView.bounds.size
        photoViewSize.width /= 2

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        for photoView in photoViews {
            photoView.layer.mask.transform = CATransform3DMakeScale(photoViewSize.width, photoViewSize.height, 1)
        }
        CATransaction.commit()
    }

    private var masked = false
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !masked {
            let maskReferenceSize: CGFloat = 1
            let spaceBetween: CGFloat = maskReferenceSize / 100
            
            let leftMaskPath = UIBezierPath()
            leftMaskPath.moveToPoint(CGPoint(x: -6 * maskReferenceSize, y: 0))
            leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize + (maskReferenceSize / 10) - spaceBetween, y: 0))
            leftMaskPath.addLineToPoint(CGPoint(x: maskReferenceSize - (maskReferenceSize / 10) - spaceBetween, y: maskReferenceSize))
            leftMaskPath.addLineToPoint(CGPoint(x: -6 * maskReferenceSize, y: maskReferenceSize))
            leftMaskPath.closePath()
            let leftMask = CAShapeLayer()
            leftMask.path = leftMaskPath.CGPath
            leftPhotoView.layer.mask = leftMask
            
            let rightMaskPath = UIBezierPath()
            rightMaskPath.moveToPoint(CGPoint(x: 7 * maskReferenceSize, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / 10) + spaceBetween, y: 0))
            rightMaskPath.addLineToPoint(CGPoint(x: (maskReferenceSize / -10) + spaceBetween, y: maskReferenceSize))
            rightMaskPath.addLineToPoint(CGPoint(x: 7 * maskReferenceSize, y: maskReferenceSize))
            rightMaskPath.closePath()
            let rightMask = CAShapeLayer()
            rightMask.path = rightMaskPath.CGPath
            rightPhotoView.layer.mask = rightMask
            
            masked = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        adjustMaskSizeWithAnimationDuration(0)
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
