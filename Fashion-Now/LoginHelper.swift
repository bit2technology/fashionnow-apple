//
//  LoginHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-12-08.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

public let LoginChangedNotificationName = "LoginChangedNotification"

extension String {

    func isEmail() -> Bool {
        let regex = NSRegularExpression(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$", options: .CaseInsensitive, error: nil)
        return regex?.firstMatchInString(self, options: nil, range: NSMakeRange(0, countElements(self))) != nil
    }
}

extension UIViewController {

    func dismissLoginModalController() {
        if let unwrappedTabBarController = (presentingViewController ?? tabBarController) as? TabBarController {
            unwrappedTabBarController.willDismissLoginController()
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func needsLogin() -> Bool {
        return false
    }
}

extension UINavigationController {

    override func needsLogin() -> Bool {
        return topViewController.needsLogin()
    }
}
