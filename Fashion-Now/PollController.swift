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

            // Clear load counter and photos
            photosLoaded = 0
            if let unwrappedPhotos = poll.photos {
                leftPhotoController.photo = unwrappedPhotos[0]
                rightPhotoController.photo = unwrappedPhotos[1]
            } else {
                leftPhotoController.photo = ParsePhoto(user: poll.createdBy!)
                rightPhotoController.photo = ParsePhoto(user: poll.createdBy!)
            }

            // Reset layout
            adjustLayout(0, animationTimingFunction: nil, callCompleteDelegate: false)

            // Caption
            captionLabel.text = poll.caption
            captionLabel.superview!.hidden = !(captionLabel.text?.fn_count > 0)
            lockView.hidden = poll.ACL?.getPublicReadAccess() != false

            // Enable gestures
            tap.enabled = poll.objectId?.fn_count > 0
            let votable = poll.createdBy?.objectId != ParseUser.currentUser().objectId
            for gesture in [doubleTap, drager] {
                gesture.enabled = votable
            }
        }
    }

    weak var editDelegate: PollEditionDelegate?
    weak var interactDelegate: PollInteractionDelegate?
    weak var loadDelegate: PollLoadDelegate?

    private weak var leftPhotoController: PhotoController!
    private weak var rightPhotoController: PhotoController!

    @IBOutlet weak var leftPhotoView: UIView!
    @IBOutlet weak var rightPhotoView: UIView!
    private var photoViews: [UIView] {
        return [leftPhotoView, rightPhotoView]
    }

    // Caption and related actions
    @IBOutlet weak var captionLabel: UILabel!
    @IBAction func captionLongPress(sender: UILongPressGestureRecognizer) {

        switch sender.state {
        case .Began, .Changed:
            // When touching caption view, show entire text.
            captionLabel.numberOfLines = 0
        default:
            captionLabel.numberOfLines = 2
        }
    }

    @IBOutlet weak var lockView: UIImageView!

    private func indexForTouch(point: CGPoint) -> Int {
        return point.x > view.bounds.width / 2 ? 2 : 1
    }

    @IBOutlet weak var tap: UITapGestureRecognizer!
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        let navController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Gallery Navigation Controller") as UINavigationController
        let gallery = navController.topViewController as GalleryController
        gallery.images = [leftPhotoController.imageView.image!, rightPhotoController.imageView.image!]
        gallery.initialImageIndex = indexForTouch(sender.locationInView(view)) - 1
        presentViewController(navController, animated: true, completion: nil)
    }

    @IBOutlet weak var doubleTap: UITapGestureRecognizer!
    @IBAction func didDoubleTap(sender: UITapGestureRecognizer) {
        interactDelegate?.pollInteracted(self)
        animateHighlight(index: indexForTouch(sender.locationInView(view)))
    }

    @IBOutlet weak var drager: UIPanGestureRecognizer!
    @IBAction func didDrag(sender: UIPanGestureRecognizer) {

        var translationX = sender.translationInView(view).x * 1.6
        let rate = translationX / self.view.bounds.width

        switch sender.state {
        case .Began:
            interactDelegate?.pollInteracted(self)
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
        interactDelegate?.pollWillHighlight(self, index: index)
        adjustLayout(rate, animationTimingFunction: CAMediaTimingFunction(name: (easeIn ? kCAMediaTimingFunctionEaseInEaseOut : kCAMediaTimingFunctionEaseOut)), callCompleteDelegate: true)
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
                self.interactDelegate?.pollDidHighlight(self)
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

        leftPhotoController.delegate = self
        rightPhotoController.delegate = self

        rightPhotoController.layoutRight = true

        captionLabel.superview!.hidden = true
        captionLabel.numberOfLines = 2

        lockView.hidden = true

        tap.requireGestureRecognizerToFail(doubleTap)

        fn_applyPollMask(leftPhotoView, rightPhotoView)
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

    func photoEdited(photoController: PhotoController) {
        if leftPhotoController.photo.isValid && rightPhotoController.photo.isValid {
            poll.photos = [leftPhotoController.photo, rightPhotoController.photo]
        } else {
            poll.photos = nil
        }
        editDelegate?.pollEdited(self)
    }

    func photoLoadFailed(photoController: PhotoController, error: NSError) {
        loadDelegate?.pollLoadFailed(self, error: error)
    }

    private var photosLoaded = 0
    func photoLoaded(photoController: PhotoController) {
        photosLoaded++
        if photosLoaded == 2 {
            loadDelegate?.pollLoaded(self)
        }
    }
}

protocol PollEditionDelegate: class {
    func pollEdited(pollController: PollController)
}
protocol PollInteractionDelegate: class {
    func pollInteracted(pollController: PollController)
    func pollWillHighlight(pollController: PollController, index: Int)
    func pollDidHighlight(pollController: PollController)
}
protocol PollLoadDelegate: class {
    func pollLoaded(pollController: PollController)
    func pollLoadFailed(pollController: PollController, error: NSError)
}
