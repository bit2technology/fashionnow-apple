//
//  PhotoComparisonController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

class PollController: UIViewController, PhotoControllerDelegate {
    
    var poll: ParsePoll = ParsePoll(user: ParseUser.currentUser()) {
        didSet {
            if let unwrappedPhotos = poll.photos {
                loadedPhotos = 0
                adjustLayout(0, animationTimingFunction: nil, callCompleteDelegate: false)
                leftPhotoController.photo = unwrappedPhotos.first!
                rightPhotoController.photo = unwrappedPhotos.last!
            } else {
                adjustLayout(0, animationTimingFunction: nil, callCompleteDelegate: false)
                leftPhotoController.photo = ParsePhoto(user: poll.createdBy!)
                rightPhotoController.photo = ParsePhoto(user: poll.createdBy!)
            }
        }
    }

    weak var delegate: PollControllerDelegate?

    private weak var leftPhotoController: PhotoController!
    private weak var rightPhotoController: PhotoController!

    private var photoViews: [UIView]!
    @IBOutlet weak var leftPhotoView: UIView!
    @IBOutlet weak var rightPhotoView: UIView!

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

    // MARK: Vote and animation

    func animateHighlight(#index: Int, withEaseInAnimation easeIn: Bool = true) {

        var rate: CGFloat!
        switch index {
        case 1:
            rate = 1
        case 2:
            rate = -1
        default:
            return
        }
        delegate?.pollControllerWillHighlight?(self, index: index)
        adjustLayout(rate, animationTimingFunction: CAMediaTimingFunction(name: (easeIn ? kCAMediaTimingFunctionEaseInEaseOut : kCAMediaTimingFunctionEaseOut)), callCompleteDelegate: true)
    }

    @IBOutlet weak var leftdoubleTap: UITapGestureRecognizer!
    @IBOutlet weak var rightdoubleTap: UITapGestureRecognizer!
    @IBAction func didDoubleTap(sender: UITapGestureRecognizer) {

        var index: Int!
        
        switch sender.view! {
        case leftPhotoView:
            index = 1
        case rightPhotoView:
            index = 2
        default:
            return
        }

        delegate?.pollControllerDidInteractWithInterface?(self)
        animateHighlight(index: index)
    }


    @IBOutlet weak var drager: UIPanGestureRecognizer!
    @IBAction func didDrag(sender: UIPanGestureRecognizer) {

        var translationX = sender.translationInView(view).x * 1.6
        let rate = translationX / self.view.bounds.width
        
        switch sender.state {
        case .Began:
            delegate?.pollControllerDidInteractWithInterface?(self)
        case .Changed:
            adjustLayout(rate, animationTimingFunction: nil, callCompleteDelegate: false)
        case .Ended:
            let velocityX = sender.velocityInView(view).x
            if abs(velocityX) > 1000 {
                animateHighlight(index: (velocityX > 0 ? 1 : 2), withEaseInAnimation: false)
                return
            }
            if abs(rate) > 0.75 {
                if rate > 0 && velocityX > 0 {
                    animateHighlight(index: 1, withEaseInAnimation: false)
                    return
                } else if rate < 0 && velocityX < 0 {
                    animateHighlight(index: 2, withEaseInAnimation: false)
                    return
                }
            }
            fallthrough
        case .Cancelled, .Failed:
            adjustLayout(0, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut), callCompleteDelegate: false)
        default:
            return
        }
    }
    
    private func adjustLayout(rate: CGFloat, animationTimingFunction: CAMediaTimingFunction?, callCompleteDelegate: Bool) {

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
        
        var translationX = rate * view.bounds.width / 2
        if abs(rate) > 1 {
            translationX -= (rate - (rate > 0 ? 1 : -1)) * view.bounds.width / 2 * 0.75
        }
        
        let draggingView = (translationX > 0 ? leftPhotoView : rightPhotoView)
        
        CATransaction.begin()
        if callCompleteDelegate {
            CATransaction.setCompletionBlock({ () -> Void in
                self.delegate?.pollControllerDidHighlight?(self)
                return
            })
        }
        var animated = false
        if let unwrappedAnimationTimingFunction = animationTimingFunction {
            CATransaction.setAnimationDuration(0.15)
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
        CATransaction.commit()
    }

    // MARK: Layout

    private func adjustMaskSizeWithAnimationDuration(duration: CFTimeInterval) {

        var photoViewSize = view.bounds.size
        photoViewSize.width /= 2

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        for photoView in photoViews {
            photoView.layer.mask?.transform = CATransform3DMakeScale(photoViewSize.width, photoViewSize.height, 1)
        }
        CATransaction.commit()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        adjustMaskSizeWithAnimationDuration(0)
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        photoViews = [leftPhotoView, rightPhotoView]

        leftPhotoController.delegate = self
        rightPhotoController.delegate = self

        rightPhotoController.layout = .Right

        // Masks

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

    optional func pollControllerDidInteractWithInterface(pollController: PollController)
    optional func pollControllerWillHighlight(pollController: PollController, index: Int)
    optional func pollControllerDidHighlight(pollController: PollController)
    optional func pollControllerDidDidFinishLoad(pollController: PollController)
}