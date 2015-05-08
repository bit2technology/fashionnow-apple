//
//  GalleryController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-03-21.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class GalleryController: FNViewController, UIScrollViewDelegate {

    var initialImageIndex: Int?
    var images: [UIImage]!
    var bgImages: [UIImage]?
    var scrollViews: [UIScrollView!] {
        return [leftScroll, rightScroll]
    }
    private var barsHidden = false

    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBOutlet weak var mainScroll, leftScroll, rightScroll: UIScrollView!
    @IBOutlet weak var leftBg, rightBg: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "viewTapped:"))

        for (index, scrollView) in enumerate(scrollViews) {
            let imageView = UIImageView(image: images[index])
            scrollView.addSubview(imageView)
            scrollView.contentSize = imageView.frame.size
            let horizontalScale = scrollView.bounds.width / scrollView.contentSize.width
            let verticalScale = scrollView.bounds.height / scrollView.contentSize.height
            scrollView.minimumZoomScale = min(horizontalScale, verticalScale)
            scrollView.zoomScale = scrollView.minimumZoomScale
        }

        if let blurredImgs = bgImages {
            for (idx, bgView) in enumerate([leftBg, rightBg]) {
                bgView.image = blurredImgs[idx]
            }
        }
    }

    func viewTapped(sender: UITapGestureRecognizer) {
        barsHidden = !barsHidden
        UIView.animateWithDuration(NSTimeInterval(UINavigationControllerHideShowBarDuration), animations: { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
            let navController = self.navigationController!
            navController.setToolbarHidden(self.barsHidden, animated: true)
            let alpha: CGFloat = self.barsHidden ? 0 : 1
            navController.navigationBar.alpha = alpha
            navController.toolbar.alpha = alpha
        })
    }

    private func centerSubview(#scrollView: UIScrollView) {
        let subview = scrollView.subviews.first as! UIView
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

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {

        if scrollView != mainScroll {
            return
        }

        rightBg.alpha = scrollView.contentOffset.x / leftScroll.frame.width
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {

        if scrollView == mainScroll {
            return nil
        }

        return (scrollView.subviews.first as! UIView)
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {

        if scrollView == mainScroll {
            return
        }

        centerSubview(scrollView: scrollView)
    }
}
