//
//  GalleryController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-03-21.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class GalleryController: UIViewController, UIScrollViewDelegate {

    var initialImageIndex: Int?
    var images: [UIImage]!
    var scrollViews: [UIScrollView] {
        return mainScroll.subviews as [UIScrollView]
    }
    private var barsHidden = false

    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBOutlet weak var mainScroll: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "viewTapped:"))

        for (index, scrollView) in enumerate(scrollViews) {
            scrollView.delegate = self
            let imageView = UIImageView(image: images[index])
            scrollView.addSubview(imageView)
            scrollView.contentSize = imageView.frame.size
            let horizontalScale = scrollView.bounds.width / scrollView.contentSize.width
            let verticalScale = scrollView.bounds.height / scrollView.contentSize.height
            scrollView.minimumZoomScale = min(horizontalScale, verticalScale)
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }

    func viewTapped(sender: UITapGestureRecognizer) {
        barsHidden = !barsHidden
        UIView.animateWithDuration(NSTimeInterval(UINavigationControllerHideShowBarDuration), animations: { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
            self.navigationController!.navigationBar.alpha = self.barsHidden ? 0 : 1
        })
    }

    private func centerSubview(#scrollView: UIScrollView) {
        let subview = scrollView.subviews.first as UIView
        subview.frame.origin.x = max((scrollView.bounds.size.width - scrollView.contentSize.width) / 2, 0.0)
        subview.frame.origin.y = max((scrollView.bounds.size.height - scrollView.contentSize.height) / 2, 0.0)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        view.layoutIfNeeded()
        for scrollView in scrollViews {
            centerSubview(scrollView: scrollView)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        PFAnalytics.fn_trackScreenInBackground("Poll: Gallery")
    }

    override func prefersStatusBarHidden() -> Bool {
        return barsHidden
    }

    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let unwrappedInitialImageIndex = initialImageIndex {
            mainScroll.contentOffset = CGPoint(x: CGFloat(unwrappedInitialImageIndex) * view.bounds.width, y: 0)
            initialImageIndex = nil
        }
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return (scrollView.subviews.first as UIView)
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerSubview(scrollView: scrollView)
    }
}
