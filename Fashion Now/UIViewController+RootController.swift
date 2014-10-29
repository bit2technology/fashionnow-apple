//
//  UIViewController+RootController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-28.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import Foundation

extension UIViewController {
    
    var customTabBarController: TabBarController? {
        get {
            return tabBarController as? TabBarController
        }
    }
    
    func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
}