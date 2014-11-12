//
//  RootController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-03.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class RootController: UIViewController, UITabBarControllerDelegate {
    
    @IBOutlet weak var contentBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var tabBarBottomMargin: NSLayoutConstraint!
    
    private(set) var cleanInterface = false
    var contentBehindTabBar = false

    var delegate: UIViewController?

    func presentLoginController() {
        performSegueWithIdentifier("Login Controller", sender: self)
    }
    
    // MARK: UITabBarControllerDelegate
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) && viewController.needsLogin() {
            presentLoginController()
            return false
        }
        return true
    }
    
    // MARK: Rotation
    
    override func prefersStatusBarHidden() -> Bool {
        return cleanInterface
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }

    override func supportedInterfaceOrientations() -> Int {

        if let unwrappedDelegate = delegate {
            return unwrappedDelegate.supportedInterfaceOrientations()
        }
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if respondsToSelector("traitCollection") {
            cleanInterface = (traitCollection.verticalSizeClass == .Compact)
        } else {
            cleanInterface = (interfaceOrientation.isLandscape && UIDevice.currentDevice().userInterfaceIdiom == .Phone)
        }
        
        tabBarBottomMargin.constant = (cleanInterface ? -tabBar.frame.height : 0)
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension UIViewController {

    var rootController: RootController? {
        get {
            var controller: UIViewController? = self
            while controller != nil && !(controller is RootController) {
                controller = controller?.parentViewController
            }
            return controller as? RootController
        }
    }
}

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.hidden = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if delegate == nil {
            delegate = rootController
            println("\(delegate) = \(rootController)")
        }

        rootController?.tabBar.items = tabBar.items
        rootController?.tabBar.selectedItem = tabBar.selectedItem
    }
}
