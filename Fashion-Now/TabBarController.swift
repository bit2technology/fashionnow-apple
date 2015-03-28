//
//  TabBarController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

/// Custom UITabBarController, for login behavior
class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
    }

    // MARK: UITabBarControllerDelegate and other selection methods

    // The controller index that will be selected with a successful login
    private var controllerIndex: Int?

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        // If controller needs login and user is loged out, show login controller
        if viewController.needsLogin() && PFAnonymousUtils.isLinkedWithUser(ParseUser.currentUser()) {
            controllerIndex = find(tabBarController.viewControllers as [UIViewController], viewController)
            presentLoginController()
            return false
        }
        return true
    }

    func presentLoginController() {
        performSegueWithIdentifier("Login Controller", sender: self)
    }

    func willDismissLoginController() {
        // If successful login and there is a controller to be selected, select new controleller
        if !PFAnonymousUtils.isLinkedWithUser(ParseUser.currentUser()) && controllerIndex != nil {
            selectedIndex = controllerIndex!
        }
        controllerIndex = nil
    }
}
