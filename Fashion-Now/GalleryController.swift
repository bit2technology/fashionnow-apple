//
//  GalleryController.swift
//  Fashion-Now
//
//  Created by Igor Camilo on 2015-03-21.
//  Copyright (c) 2015 Bit2 Software. All rights reserved.
//

import UIKit

class GalleryController: FNViewController, UIScrollViewDelegate {

    weak var pollController: PollController!
    var initialImgIdx: Int?
    private var currentImgIdx = 0
    var images: [UIImage]!
    var blurImages: [UIImage]?
    private var barsHidden = false
    private var imgsAdjusted = false

    @IBOutlet weak var mainScroll, leftScroll, rightScroll: UIScrollView!
    @IBOutlet weak var leftBg, rightBg: UIImageView!

    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func vote(sender: AnyObject) {
        pollController.animateHighlight(index: currentImgIdx++, withEaseInAnimation: false, source: .Extern)
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: "toggleBarsHidden:")
        view.addGestureRecognizer(tap)

        // Be able to vote if poll is not from current user
        if pollController.poll.createdBy != ParseUser.current() {
            let doubleTap = UITapGestureRecognizer(target: self, action: "vote:")
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)
            tap.requireGestureRecognizerToFail(doubleTap)
        }

        // set blurred backgrounds
        if let bgImgs = blurImages {
            for (idx, bgView) in enumerate([leftBg, rightBg]) {
                bgView.image = bgImgs[idx]
            }
        }
    }

    func toggleBarsHidden(sender: UITapGestureRecognizer) {
        hideBars(!barsHidden)
    }

    private func hideBars(hidden: Bool) {

        if barsHidden == hidden {
            return
        }

        barsHidden = hidden
        UIView.animateWithDuration(NSTimeInterval(UINavigationControllerHideShowBarDuration), animations: { () -> Void in
            self.setNeedsStatusBarAppearanceUpdate()
            let navController = self.navigationController!
            navController.setToolbarHidden(self.pollController.poll.createdBy != ParseUser.current() ? self.barsHidden : true, animated: true)
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

        if !imgsAdjusted {
            imgsAdjusted = true

            // Add image views
            for (idx, scrollView) in enumerate([leftScroll, rightScroll]) {
                let imgView = UIImageView(image: images[idx])
                scrollView.addSubview(imgView)
                scrollView.contentSize = imgView.frame.size
                let horizontalScale = scrollView.bounds.width / scrollView.contentSize.width
                let verticalScale = scrollView.bounds.height / scrollView.contentSize.height
                scrollView.minimumZoomScale = min(horizontalScale, verticalScale)
                scrollView.zoomScale = scrollView.minimumZoomScale
            }

            for scrollView in [leftScroll, rightScroll] {
                centerSubview(scrollView: scrollView)
            }
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

        if let imgIdx = initialImgIdx {
            mainScroll.contentOffset = CGPoint(x: CGFloat(imgIdx) * view.bounds.width, y: 0)
            currentImgIdx = imgIdx
            initialImgIdx = nil
        }
    }

    // MARK: - UIScrollViewDelegate

    // Main
    func scrollViewDidScroll(scrollView: UIScrollView) {

        if scrollView != mainScroll {
            return
        }

        hideBars(true)
        rightBg.alpha = scrollView.contentOffset.x / leftScroll.frame.width
        currentImgIdx = rightBg.alpha > 0.5 ? 1 : 0
    }

    // Subs
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
