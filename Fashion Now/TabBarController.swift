//
//  TabBarController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func supportedInterfaceOrientations() -> Int {
        // iPhone: portrait only; iPad: all.
        var supportedInterfaceOrientations = UIInterfaceOrientationMask.Portrait
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            supportedInterfaceOrientations = .All
        }
        return Int(supportedInterfaceOrientations.rawValue)
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
    }

    // MARK: UITabBarControllerDelegate and other selection methods

    // The controller index that will be selected with a successful login
    var controllerIndex: Int?

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        // If controller needs login and user is loged out, show login controller
        if viewController.needsLogin() && PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            controllerIndex = find((tabBarController.viewControllers as [UIViewController]), viewController)
            tabBarController.performSegueWithIdentifier("Login Controller", sender: self)
            return false
        }
        return true
    }

    func willDismissLoginController() {
        // If successful login and there is a controller to be selected, select new controleller
        if !PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) && controllerIndex != nil {
            selectedIndex = controllerIndex!
        }
        controllerIndex = nil
    }
}
