//
//  TabBarController.swift
//  Fashion Now
//
//  Created by Igor Camilo on 2014-10-29.
//  Copyright (c) 2014 Bit2 Software. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
    
    // Substitute for bottom layout guide
    var tabBarHeight: CGFloat {
        get {
            return view.bounds.height - tabBar.frame.minY
        }
    }
    
    private(set) var tabBarHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.clipsToBounds = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if respondsToSelector("traitCollection") {
            tabBarHidden = (traitCollection.verticalSizeClass == .Compact)
        } else {
            tabBarHidden = (interfaceOrientation.isLandscape && UIDevice.currentDevice().userInterfaceIdiom == .Phone)
        }
        
        var tabBarFrame = tabBar.frame
        tabBarFrame.origin.y = view.bounds.height - (tabBarHidden ? 0 : tabBarFrame.height)
        tabBar.frame = tabBarFrame
    }
}