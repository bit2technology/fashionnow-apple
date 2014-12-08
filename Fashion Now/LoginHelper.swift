//
//  LoginHelper.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-12-08.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

public let LoginChangedNotificationName = "LoginChangedNotification"

extension UIViewController {

    func needsLogin() -> Bool {
        return false
    }
}

extension UINavigationController {

    override func needsLogin() -> Bool {
        return self.topViewController.needsLogin()
    }
}
