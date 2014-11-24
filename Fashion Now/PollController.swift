//
//  PhotoComparisonController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

internal class PollController: UIViewController, PhotoControllerDelegate {
    
    var poll: ParsePoll = ParsePoll() {
        didSet {
            if let unwrappedPhotos = poll.photos {
                loadedPhotos = 0
                adjustVoteLayout(0, animationTimingFunction: nil, voteCompleted: false)
                leftPhotoController.photo = unwrappedPhotos[0]
                rightPhotoController.photo = unwrappedPhotos[1]
            }
        }
    }

    var delegate: PollControllerDelegate?

    private var leftPhotoController: PhotoController!
    private var rightPhotoController: PhotoController!

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

    func animateAndVote(#index: Int, easeIn: Bool) {

        var rate: CGFloat!
        switch index {
        case 0:
            rate = 1
        case 1:
            rate = -1
        default:
            return
        }
        adjustVoteLayout(rate, animationTimingFunction: CAMediaTimingFunction(name: (easeIn ? kCAMediaTimingFunctionEaseInEaseOut : kCAMediaTimingFunctionEaseOut)), voteCompleted: true)
    }

    var imageButtonsHidden: Bool = false {
        didSet {
            for photoController in [leftPhotoController, rightPhotoController] {
                photoController.imageButtonsHidden = self.imageButtonsHidden
            }
        }
    }

    var voteGesturesEnabled: Bool = false {
        didSet {
            for gesture in [drager, leftdoubleTap, rightdoubleTap] {
                gesture.enabled = voteGesturesEnabled
            }
        }
    }

    @IBOutlet weak var leftdoubleTap: UITapGestureRecognizer!
    @IBOutlet weak var rightdoubleTap: UITapGestureRecognizer!
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

        delegate?.pollControllerDidInteractWithVoteInterface?(self)
        animateAndVote(index: index, easeIn: true)
    }


    @IBOutlet var drager: UIPanGestureRecognizer!
    @IBAction func didDrag(sender: UIPanGestureRecognizer) {

        var translationX = sender.translationInView(containerView).x * 1.6
        let rate = translationX / self.containerView.bounds.width
        
        switch sender.state {
        case .Began:
            delegate?.pollControllerDidInteractWithVoteInterface?(self)
        case .Changed:
            adjustVoteLayout(rate, animationTimingFunction: nil, voteCompleted: false)
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
            adjustVoteLayout(0, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut), voteCompleted: false)
        default:
            return
        }
    }
    
    private func adjustVoteLayout(rate: CGFloat, animationTimingFunction: CAMediaTimingFunction?, voteCompleted: Bool) {

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

        // Adjust layers transform for rate
        
        var translationX = rate * containerView.bounds.width / 2
        if abs(rate) > 1 {
            translationX -= (rate - (rate > 0 ? 1 : -1)) * containerView.bounds.width / 2 * 0.75
        }
        
        let draggingView = (translationX > 0 ? leftPhotoView : rightPhotoView)
        
        CATransaction.begin()
        var animated = false
        if let unwrappedAnimationTimingFunction = animationTimingFunction {
            CATransaction.setAnimationDuration(0.25)
            CATransaction.setAnimationTimingFunction(unwrappedAnimationTimingFunction)
            animated = true
        } else {
            CATransaction.setDisableActions(true)
        }
        for photoView in photoViews {
            let isDraggingView = (photoView == draggingView)
            setLayerTransform(CATransform3DMakeTranslation((isDraggingView ? translationX / 2 : 0), 0, 0), toView: photoView, explicitAnimated: (animationTimingFunction != nil))
            setMaskTranslateX(translationX * (isDraggingView ? 0.75 : 1.25), view: photoView)
        }
        if voteCompleted {
            CATransaction.setCompletionBlock({ () -> Void in
                self.delegate?.pollControllerDidVote?(self, animated: animated)
                return
            })
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

//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        coordinator.animateAlongsideTransition({ (context) -> Void in
//            self.adjustMaskSizeWithAnimationDuration(context.transitionDuration())
//        }, completion: nil)
//    }

    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        adjustMaskSizeWithAnimationDuration(duration)
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        photoViews = [leftPhotoView, rightPhotoView]

        leftPhotoController.delegate = self
        rightPhotoController.delegate = self
    }

    // MARK: PhotoControllerDelegate

    var loadedPhotos = 0
    func photoController(photoController: PhotoController, didLoadPhoto photo: ParsePhoto) {
        loadedPhotos++
        if loadedPhotos >= 2 {
            delegate?.pollControllerDidDidFinishLoad?(self)
        }
    }

    func photoController(photoController: PhotoController, didEditPhoto photo: ParsePhoto) {
        if leftPhotoController.photo.isValid && rightPhotoController.photo.isValid {
            poll.photos = [leftPhotoController.photo, rightPhotoController.photo]
        } else {
            poll.photos = nil
        }
        delegate?.pollController?(self, didEditPoll: poll)
    }
}

@objc protocol PollControllerDelegate {

    optional func pollController(pollController: PollController, didEditPoll poll:ParsePoll)

    optional func pollControllerDidInteractWithVoteInterface(pollController: PollController)
    optional func pollControllerDidVote(pollController: PollController, animated: Bool)

    optional func pollControllerDidDidFinishLoad(pollController: PollController)
}
