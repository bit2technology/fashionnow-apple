//
//  TabBarController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-11-15.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let unwrappedId = segue.identifier {
            
            switch unwrappedId {
            case "Login Controller":
                return
            default:
                return
            }
        }
    }

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

    // MARK: UITabBarControllerDelegate

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {

        if viewController.needsLogin() && PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            let controllerIndex = find((tabBarController.viewControllers as [UIViewController]), viewController)
            tabBarController.performSegueWithIdentifier("Login Controller", sender: controllerIndex)
            return false
        }
        return true
    }
}
